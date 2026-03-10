//
//  ContentView.swift
//  ChatBotMain
//

import SwiftUI
import OpenAI

class ChatController: ObservableObject {
    @Published var messages: [Message] = []
    
    private let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    
    lazy var openAI: OpenAI = {
            return OpenAI(apiToken: apiKey)
        }()
    func sendNewMessage(content: String) {
        let userMessage = Message(content: content, isUser: true)
        self.messages.append(userMessage)
        getBotReply()
    }
    
    func getBotReply() {
        let personality = [
            Chat(
                role: .user,
                content: "Respond to everything following these instructions: High-Pressure / Savage, use tough love to shame a users bad spending habits"
            )
        ]
        
        openAI.chats(
            query: .init(
                model: .gpt3_5Turbo,
                messages: personality + self.messages.map {
                    Chat(role: .user, content: $0.content)
                }
            )
        ) { result in
            
            switch result {
                
            case .success(let success):
                guard let choice = success.choices.first else { return }
                
                let message = choice.message.content
                
                DispatchQueue.main.async {
                    self.messages.append(
                        Message(content: message ?? "", isUser: false)
                    )
                }
                
            case .failure(let failure):
                print(failure)
            }
        }
    }
}

struct Message: Identifiable {
    var id: UUID = .init()
    var content: String
    var isUser: Bool
}

struct ContentView: View {
    
    @StateObject var chatController: ChatController = .init()
    @State var string: String = ""
    
    var body: some View {
        
        ScrollViewReader { proxy in
            
            VStack {
                
                ScrollView {
                    ForEach(chatController.messages) { message in
                        MessageView(message: message)
                            .padding(5)
                            .id(message.id)
                    }
                }
                .onChange(of: chatController.messages.count) { _ in
                    if let last = chatController.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    
                    TextField("Message...", text: $string, axis: .vertical)
                        .onSubmit {
                            sendMessage()
                        }
                        .padding(5)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "paperplane")
                    }
                }
                .padding()
            }
        }
    }

    func sendMessage() {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty { return }
        
        chatController.sendNewMessage(content: trimmed)
        string = ""
    }
}

struct MessageView: View {
    
    var message: Message
    
    var body: some View {
        
        HStack {
            
            if message.isUser {
                Spacer()
            }
            
            Text(message.content)
                .padding(12)
                .foregroundColor(.white)
                .background(message.isUser ? Color.blue : Color.gray)
                .cornerRadius(16)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 300,
                       alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
        .padding(.horizontal, 10)
    }
}
