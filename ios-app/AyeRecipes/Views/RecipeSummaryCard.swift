//
//  RecipeSummaryCard.swift
//  AyeRecipes
//
//  Created by Jose Alberto Montero Martinez on 1/12/26.
//

import SwiftUI

struct RecipeSummaryCard: View {
    let title: String
    
    var body: some View {
        VStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 1.0, green: 0.27, blue: 0.0).opacity(0.3))
                .frame(height: 100)
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
    RecipeSummaryCard(title: "Pasta Carbonara")
}
