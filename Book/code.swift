//
//  ContentView.swift
//  Simple Code
//
//  Created by Ongar.dev on 27/04/2023.
//

import SwiftUI

struct MoodEntry: Hashable, Codable {
    var mood: String
    var comment: String
    var photo: UIImage?

    enum CodingKeys: String, CodingKey {
        case mood
        case comment
        case photo
    }

    init(mood: String, comment: String, photo: UIImage?) {
        self.mood = mood
        self.comment = comment
        self.photo = photo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mood = try container.decode(String.self, forKey: .mood)
        comment = try container.decode(String.self, forKey: .comment)
        if let imageData = try container.decodeIfPresent(Data.self, forKey: .photo) {
            photo = UIImage(data: imageData)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mood, forKey: .mood)
        try container.encode(comment, forKey: .comment)
        if let imageData = photo?.jpegData(compressionQuality: 1.0) {
            try container.encode(imageData, forKey: .photo)
        }
    }
}


class MoodTracker: ObservableObject {
    @Published var entries: [MoodEntry] = []

    init() {
        load()
    }

    func addEntry(_ entry: MoodEntry) {
        entries.append(entry)
        save()
    }

    func save() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "MoodEntries")
        }
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: "MoodEntries") {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([MoodEntry].self, from: data) {
                entries = decoded
            }
        }
    }
}

struct ContentView: View {
    @State var selectedMood: String = ""
    @State var comment: String = ""
    @State var photo: UIImage?
    @ObservedObject var moodTracker = MoodTracker()

    let moods = ["Счастливый", "Грустный", "Удивленный", "Спокойный"]

    var body: some View {
        NavigationView {
            VStack {
                Text("Какое ваше настроение сегодня?")
                    .font(.title)
                    .padding()

                Picker(selection: $selectedMood, label: Text("")) {
                    ForEach(moods, id: \.self) { mood in
                        Text(mood)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                TextField("Комментарий", text: $comment)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    let newEntry = MoodEntry(mood: selectedMood, comment: comment, photo: photo)
                    moodTracker.addEntry(newEntry)
                    selectedMood = ""
                    comment = ""
                    photo = nil
                }) {
                    Text("Добавить запись")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()

                Spacer()

                List {
                    ForEach(moodTracker.entries, id: \.self) { entry in
                        HStack {
                            Text(entry.mood)
                            Spacer()
                            Text(entry.comment)
                            Spacer()
                            if let image = entry.photo {
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: 50, height: 50)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Дневник настроения")
        }
        .onAppear {
            moodTracker.load()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
