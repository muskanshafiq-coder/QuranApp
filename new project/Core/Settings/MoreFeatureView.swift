import SwiftUI

struct MoreFeaturesView: View {
    
    let features: [(icon: String, color: Color, title: String, desc: String)] = [
        ("applewatch", .black, "feature_apple_watch_title", "feature_apple_watch_desc"),
        ("megaphone.fill", .purple, "feature_ads_free_title", "feature_ads_free_desc"),
        ("film.fill", .red, "feature_audio_sync_title", "feature_audio_sync_desc"),
        ("car.fill", .green, "feature_carplay_title", "feature_carplay_desc")
    ]
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @AppStorage(UserDefaultsManager.Keys.hasCompletedOnboarding) private var hasCompletedOnboarding: Bool = false
    @State private var showMoreFeatures = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                
                Text("more_features")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("more_features_description")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                
                // Adaptive layout
                if horizontalSizeClass == .compact {
                    // Portrait: vertical list
                    VStack(spacing: 16) {
                        ForEach(features, id: \.title) { feature in
                            featureRow(icon: feature.icon,
                                       color: feature.color,
                                       title: feature.title,
                                       desc: feature.desc)
                        }
                    }
                } else {
                    // Landscape: evenly spaced horizontal row
                    HStack(alignment: .top, spacing: 24) {
                        ForEach(features, id: \.title) { feature in
                            featureColumn(icon: feature.icon,
                                          color: feature.color,
                                          title: feature.title,
                                          desc: feature.desc)
                                .frame(maxWidth: 150) // limit width per feature for better readability
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                }
                
                Spacer(minLength: 50)
                
                Button {
                    hasCompletedOnboarding = true
                } label: {
                    Text("start_button")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .padding(.horizontal)
                }
                
            }
            .padding(.top, 40)
            .padding(.bottom, 20)
        }
        .background(Color.app.ignoresSafeArea())
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarBackButtonHidden()
    }
}

// Feature Column (for horizontal row)
func featureColumn(icon: String, color: Color, title: String, desc: String) -> some View {
    VStack(alignment: .center, spacing: 8) {
        Image(systemName: icon)
            .font(.system(size: 28))
            .foregroundColor(color)
        
        Text(LocalizedStringKey(title))
            .font(.headline)
            .multilineTextAlignment(.center)
        
        Text(LocalizedStringKey(desc))
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }
}

// Feature Row (for vertical list)
func featureRow(icon: String, color: Color, title: String, desc: String) -> some View {
    HStack(alignment: .top, spacing: 16) {
        Image(systemName: icon)
            .font(.system(size: 22))
            .foregroundColor(color)
            .frame(width: 30)
            .alignmentGuide(.top) { d in d[.top] }
        
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStringKey(title))
                .font(.headline)
            
            Text(LocalizedStringKey(desc))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        
        Spacer()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
}

