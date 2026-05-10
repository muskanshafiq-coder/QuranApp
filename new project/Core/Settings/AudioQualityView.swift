//
//  AudioQualityView.swift
//

import SwiftUI



struct AudioQualityView: View {
    
    @State private var streamingSelection: AudioQuality = .automatic
    @State private var downloadSelection: AudioQuality = .normal
    
    enum AudioQuality {
        case automatic, high, normal
    }
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading, spacing: 20) {
                
                Text("Streaming")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                VStack(spacing: 0) {
                    qualityRow(
                        title: "Automatic (Recommended)",
                        selected: streamingSelection == .automatic,
                        locked: false
                    ) {
                        streamingSelection = .automatic
                    }
                    
                    Divider()
                    
                    qualityRow(
                        title: "High",
                        selected: streamingSelection == .high,
                        locked: true
                    ) {}
                }
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Text("Automatic is equivalent to 64kbit/s and high is 192kbit/s. If your internet isn’t very fast, please keep automatic settings selected to get the best experience.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                
                Text("Downloading")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                VStack(spacing: 0) {
                    qualityRow(
                        title: "Normal (Recommended)",
                        selected: downloadSelection == .normal,
                        locked: false
                    ) {
                        downloadSelection = .normal
                    }
                    
                    Divider()
                    
                    qualityRow(
                        title: "High",
                        selected: downloadSelection == .high,
                        locked: true
                    ) {}
                }
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Audio Quality")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    func qualityRow(
        title: String,
        selected: Bool,
        locked: Bool,
        action: @escaping () -> Void
    ) -> some View {
        
        Button(action: {
            if !locked { action() }
        }) {
            HStack {
                Text(title)
                    .foregroundColor(locked ? .gray : .primary)
                
                Spacer()
                
                if locked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.red)
                } else if selected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.red)
                }
            }
            .padding()
        }
    }
}
