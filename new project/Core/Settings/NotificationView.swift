//
//  NotificationView.swift
//

import SwiftUI

struct NotificationView: View {

    var body: some View {
        VStack(spacing: 25) {

            Image(systemName: "bell.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Text("notification_title")
                .font(.system(size: 30, weight: .bold))

            Text("verse_of_the_day_permission")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Spacer(minLength: 50)

            NavigationLink {
                MoreFeaturesView()
            } label: {
                Text("allow_button")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .padding(.horizontal, 30)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 40)
        .background(Color.app.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
}
