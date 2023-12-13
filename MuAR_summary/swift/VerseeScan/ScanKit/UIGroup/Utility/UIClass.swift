//
//  UIClass.swift
//  VerseeScan
//
//  Created by 张裕阳 on 2023/7/7.
//

import Foundation
import SwiftUI

public extension Button {
    func withLoginStyles() -> some View {
        self.background(Color.black)
            .frame(width: 280, height: 45, alignment: .center)
            .cornerRadius(8)
    }
}

public extension Color {
    static let Orange = Color("Orange")
}

public extension TextField {
    func withLoginStyles() -> some View {
        self.padding()
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 2)
            )
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .padding(.bottom, 20)
    }
}

public extension SecureField {
    func withSecureFieldStyles() -> some View {
        self.padding()
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 2)
            )
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .padding(.bottom, 20)
    }
}

public extension Text {
    func withButtonStyles() -> some View {
        self.foregroundColor(.white)
            .padding()
            .frame(width: 320, height: 60)
            .background(Color.black)
            .cornerRadius(15.0)
            .font(.headline)
    }
    
    func withSettingStyles() -> some View {
        self.foregroundColor(.black)
            .frame(height: 30)
            .background(Color.white)
    }
}

public extension Picker {
    func withLoginStyles() -> some View {
        self.pickerStyle(SegmentedPickerStyle())
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 2)
            )
            .padding(.bottom, 20)
    }
}
