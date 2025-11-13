/// AddBookmarkView.swift
/// A sheet interface for adding new bookmarks to the app.
/// This file contains:
/// - Form fields for title and URL input
/// - URL validation and duplicate checking
/// - Animated save button with loading state
/// - Error handling and user feedback
/// The view ensures data validity before saving new bookmarks.

import Foundation
import SwiftUI

// MARK: - Form Field Type

private enum Field {
    case title, url
}

/// A simple sheet that lets the user type in a bookmark title and URL,
/// then save it to the ViewModel.
struct AddBookmarkView: View {
    @EnvironmentObject var viewModel: BookmarkViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var title: String = ""
    @State private var url: String = ""
    @State private var showingDuplicateAlert = false
    @State private var isValidUrl = true
    @State private var isSaving = false
    @FocusState private var focusedField: Field?

    var body: some View {
        VStack(spacing: 0) {
            AddBookmarkHeader(dismiss: dismiss)

            VStack(alignment: .leading, spacing: UIConstants.Layout.extraLargeSpacing) {
                BookmarkFormFields(
                    title: $title,
                    url: $url,
                    isValidUrl: $isValidUrl,
                    focusedField: $focusedField,
                    colorScheme: colorScheme,
                    onSubmit: {
                        if canSave {
                            saveBookmarkWithAnimation()
                        }
                    }
                )

                Spacer()

                SaveButton(
                    isSaving: isSaving,
                    canSave: canSave,
                    action: saveBookmarkWithAnimation
                )
            }
            .padding(UIConstants.Layout.doublePadding)
        }
        .frame(width: UIConstants.Window.sheetWidth)
        .background(colorScheme == .dark ? Color(white: UIConstants.Style.mediumOpacity) : .white)
        .alert("Duplicate URL", isPresented: $showingDuplicateAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This URL already exists in your bookmarks.")
        }
        .onAppear {
            focusedField = .title
        }
    }

    private func validateUrl(_ urlString: String) -> Bool {
        // First check if it's a valid URL with a scheme
        if let url = URL(string: urlString), url.scheme != nil {
            return true
        }

        // If no scheme, check if it would be valid with https://
        let urlWithScheme = "https://" + urlString
        return URL(string: urlWithScheme) != nil
    }

    private var canSave: Bool {
        !title.isEmpty && !url.isEmpty && validateUrl(url) && !isSaving
    }

    private func saveBookmarkWithAnimation() {
        guard canSave else { return }

        isSaving = true

        // Format URL if needed
        var formattedUrl = url
        if !url.lowercased().hasPrefix("http://"), !url.lowercased().hasPrefix("https://") {
            formattedUrl = "https://" + url
        }

        // Check if URL already exists
        if Bookmark.urlExists(formattedUrl, in: viewModel.bookmarks) {
            showingDuplicateAlert = true
            isSaving = false
            return
        }

        let newBookmark = Bookmark(title: title, url: formattedUrl)
        Task {
            try? await Task.sleep(for: .milliseconds(500)) // Add a small delay for visual feedback
            await viewModel.addBookmark(bookmark: newBookmark)
            dismiss()
        }
    }
}

// MARK: - Header Component

private struct AddBookmarkHeader: View {
    let dismiss: DismissAction

    var body: some View {
        HStack {
            Text("Add Bookmark")
                .font(.system(size: UIConstants.Typography.titleText, weight: UIConstants.Typography.boldWeight))
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: UIConstants.Typography.titleText))
            }
        }
        .padding(UIConstants.Layout.doublePadding)
        .background(Color.primary.opacity(UIConstants.Style.subtleOpacity))
    }
}

// MARK: - Form Fields Component

private struct BookmarkFormFields: View {
    @Binding var title: String
    @Binding var url: String
    @Binding var isValidUrl: Bool
    @FocusState.Binding var focusedField: Field?
    let colorScheme: ColorScheme
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: UIConstants.Layout.extraLargeSpacing) {
            FormField(
                title: "Title",
                text: $title,
                field: .title,
                focusedField: $focusedField,
                colorScheme: colorScheme,
                onSubmit: onSubmit
            )

            FormField(
                title: "URL",
                text: $url,
                field: .url,
                focusedField: $focusedField,
                colorScheme: colorScheme,
                showError: !url.isEmpty && !validateUrl(url),
                errorMessage: "Please enter a valid URL",
                onTextChange: { newValue in
                    isValidUrl = validateUrl(newValue)
                },
                onSubmit: onSubmit
            )
        }
    }

    private func validateUrl(_ urlString: String) -> Bool {
        // First check if it's a valid URL with a scheme
        if let url = URL(string: urlString), url.scheme != nil {
            return true
        }

        // If no scheme, check if it would be valid with https://
        let urlWithScheme = "https://" + urlString
        return URL(string: urlWithScheme) != nil
    }
}

// MARK: - Form Field Component

private struct FormField: View {
    let title: String
    @Binding var text: String
    let field: Field
    @FocusState.Binding var focusedField: Field?
    let colorScheme: ColorScheme
    var showError: Bool = false
    var errorMessage: String = ""
    var onTextChange: ((String) -> Void)?
    var onSubmit: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Layout.smallSpacing) {
            Text(title)
                .font(.system(size: UIConstants.Typography.bodyText, weight: UIConstants.Typography.mediumWeight))
                .foregroundColor(.secondary)

            TextField("Enter \(title.lowercased())", text: $text)
                .textFieldStyle(.plain)
                .padding(UIConstants.Layout.mediumPadding)
                .background(
                    RoundedRectangle(cornerRadius: UIConstants.Style.smallRadius)
                        .fill(colorScheme == .dark ? Color(white: UIConstants.Style.mediumOpacity) : .white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: UIConstants.Style.smallRadius)
                        .stroke(
                            focusedField == field
                                ? Color.blue.opacity(UIConstants.Style.fullOpacity)
                                : Color.primary.opacity(UIConstants.Style.lightOpacity),
                            lineWidth: focusedField == field ? UIConstants.Style.thickBorder : UIConstants.Style
                                .thinBorder
                        )
                )
                .focused($focusedField, equals: field)
                .onChange(of: text) { _, newValue in
                    onTextChange?(newValue)
                }
                .onSubmit {
                    onSubmit?()
                }

            if showError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Save Button Component

private struct SaveButton: View {
    let isSaving: Bool
    let canSave: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text("Save Bookmark")
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                canSave
                    ? Color.blue
                    : Color.blue.opacity(UIConstants.Style.fullOpacity)
            )
            .cornerRadius(UIConstants.Style.smallRadius)
            .foregroundColor(.white)
        }
        .disabled(!canSave || isSaving)
    }
}
