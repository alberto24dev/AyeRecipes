//
//  RecipeSummaryCard.swift
//  AyeRecipes
//
//  Created by Jose Alberto Montero Martinez on 1/12/26.
//

import SwiftUI

struct RecipeSummaryCard: View {
    let title: String
    let imageUrl: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RemoteImage(url: imageUrl)
                .frame(width: 160, height: 100)
                .clipped()
            
            Text(title)
                .font(.headline)
                .lineLimit(1)
                .padding([.horizontal, .bottom], 8)
                .padding(.top, 4)
        }
        .frame(width: 160)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    RecipeSummaryCard(title: "Pasta Carbonara", imageUrl: nil)
}
