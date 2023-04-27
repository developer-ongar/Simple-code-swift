import SwiftUI

struct Habit: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var goal: Int
    var progress: Int
    var icon: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case goal
        case progress
        case icon
    }

    init(title: String, description: String, goal: Int, progress: Int, icon: String) {
        self.title = title
        self.description = description
        self.goal = goal
        self.progress = progress
        self.icon = icon
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(goal, forKey: .goal)
        try container.encode(progress, forKey: .progress)
        try container.encode(icon, forKey: .icon)
    }
}


class HabitTracker: ObservableObject {
    @Published var habits: [Habit] = []

    init() {
        load()
    }

    func addHabit(_ habit: Habit) {
        habits.append(habit)
        save()
    }

    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
            save()
        }
    }

    func deleteHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits.remove(at: index)
            save()
        }
    }

    func save() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(habits) {
            UserDefaults.standard.set(encoded, forKey: "Habits")
        }
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: "Habits") {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([Habit].self, from: data) {
                habits = decoded
            }
        }
    }
}

struct HabitFormView: View {
    @Binding var habit: Habit
    @State var showingImagePicker = false
    @State var image: UIImage?

    var body: some View {
        VStack(alignment: .leading) {
            TextField("Название", text: $habit.title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Описание", text: $habit.description)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            HStack {
                Text("Цель:")
                Spacer()
                Stepper(value: $habit.goal, in: 1...100) {
                    Text("\(habit.goal)")
                }
            }
            .padding()

            HStack {
                Text("Прогресс:")
                Spacer()
                Stepper(value: $habit.progress, in: 0...habit.goal) {
                    Text("\(habit.progress)")
                }
            }
            .padding()

            Button(action: {
                self.showingImagePicker = true
            }) {
                Text("Добавить иконку")
            }
            .padding()

            if image != nil {
                Image(uiImage: image!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .padding()
            }

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
            ImagePicker(image: self.$image)
        }
    }

    func loadImage() {
        guard let inputImage = image else { return }
        habit.icon = UUID().uuidString
        let imageUrl = getDocumentsDirectory().appendingPathComponent(habit.icon)
        if let jpegData = inputImage.jpegData(compressionQuality: 0.8) {
            try? jpegData.write(to: imageUrl, options: [.atomicWrite, .completeFileProtection])
        }
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

struct HabitListView: View {
    @ObservedObject var habitTracker: HabitTracker

    var body: some View {
        NavigationView {
            List {
                ForEach(habitTracker.habits) { habit in
                    NavigationLink(destination: HabitDetailView(habit: habit, habitTracker: habitTracker)) {
                        HStack {
                            Image(uiImage: habitTracker.getImage(for: habit.icon))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                                .padding()

                            VStack(alignment: .leading) {
                                Text(habit.title)
                                    .font(.headline)
                                Text(habit.description)
                            }

                            Spacer()

                            VStack {
                                Text("\(habit.progress)/\(habit.goal)")
                                    .font(.headline)
                                Text("Завершено")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        habitTracker.deleteHabit(habitTracker.habits[index])
                    }
                }
            }
            .navigationBarTitle("Прогресс Асенёка")
            .navigationBarItems(trailing: Button(action: {
                let newHabit = Habit(title: "", description: "", goal: 10, progress: 0, icon: "")
                habitTracker.addHabit(newHabit)
            }) {
                Image(systemName: "plus")
            })
        }
    }
}

struct HabitDetailView: View {
    @State var habit: Habit
    @ObservedObject var habitTracker: HabitTracker
    @State var showingEditForm = false

    var body: some View {
        VStack {
            Image(uiImage: habitTracker.getImage(for: habit.icon))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                .padding()

            Text(habit.title)
                .font(.title)
                .padding()

            Text(habit.description)
                .padding()

            HStack {
                Text("Цель:")
                Spacer()
                Text("\(habit.goal)")
            }
            .padding()

            HStack {
                Text("Прогресс:")
                Spacer()
                Text("\(habit.progress)")
            }
            .padding()

            Button(action: {
                self.showingEditForm = true
            }) {
                Text("Редактировать")
            }
            .padding()

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingEditForm) {
            HabitFormView(habit: $habit)
                .onDisappear {
                    habitTracker.updateHabit(habit)
                }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }

            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
        // Ничего не нужно обновлять в ImagePicker
    }
}


struct HabitIconView: View {
    var iconName: String
    var habitTracker: HabitTracker

    var body: some View {
        Image(uiImage: habitTracker.getImage(for: iconName))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 50, height: 50)
            .padding()
    }
}


extension HabitTracker {
    func getImage(for icon: String) -> UIImage {
        let imageUrl = HabitTracker.getDocumentsDirectory().appendingPathComponent(icon)
        if let imageData = try? Data(contentsOf: imageUrl) {
            return UIImage(data: imageData)!
        } else {
            return UIImage(systemName: "star")!
        }
    }

    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}

struct ContentView: View {
    @ObservedObject var habitTracker = HabitTracker()

    var body: some View {
        ZStack {
            Color.pink.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            HabitListView(habitTracker: habitTracker)
        }
        .background(Color.pink.opacity(0.5))
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

