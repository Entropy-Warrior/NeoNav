/// ContentView.swift
/// The main window interface of the app with split view layout.
/// This file contains:
/// - Bookmark list with selection and reordering
/// - Detail view for selected bookmarks
/// - Toolbar actions (add, remove, refresh)
/// - Selection state management
/// The view provides the primary interface for managing bookmarks.

import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Main View

struct ContentView: View {
    @EnvironmentObject var viewModel: BookmarkViewModel
    @StateObject private var selectionManager: BookmarkSelectionManager
    @State private var showingAddSheet = false
    @SceneStorage("ContentView.splitPosition") private var splitPosition: Double = UIConstants.MainWindow
        .defaultSplitPosition

    init() {
        let tempViewModel = BookmarkViewModel()
        _selectionManager = StateObject(wrappedValue: BookmarkSelectionManager(viewModel: tempViewModel))
    }

    var body: some View {
        NavigationSplitView {
            List(selection: Binding(
                get: { selectionManager.selectedBookmark },
                set: { newSelection in
                    Task { @MainActor in
                        selectionManager.select(newSelection)
                    }
                }
            )) {
                ForEach(viewModel.bookmarks) { bookmark in
                    BookmarkRow(bookmark: bookmark)
                        .tag(bookmark)
                }
                .onMove { source, destination in
                    Task {
                        await viewModel.moveBookmarks(from: source, to: destination)
                    }
                }
                .onDelete { indexSet in
                    Task {
                        for index in indexSet {
                            await viewModel.deleteBookmark(bookmark: viewModel.bookmarks[index])
                        }
                    }
                }
            }
            .navigationTitle("NeoNav")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: { showingAddSheet = true }) {
                        Label("Add Bookmark", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigation) {
                    Button {
                        Task {
                            await selectionManager.deleteSelected()
                        }
                    } label: {
                        Label("Remove Bookmark", systemImage: "minus")
                    }
                    .disabled(selectionManager.selectedBookmark == nil)
                }
                ToolbarItem(placement: .navigation) {
                    Button {
                        Task { await viewModel.refreshAllFavicons() }
                    } label: {
                        Label("Refresh Icons", systemImage: "arrow.clockwise")
                    }
                }
            }
        } detail: {
            if let bookmark = selectionManager.getUpdatedBookmark() {
                DetailView(bookmark: bookmark)
                    .id(bookmark.id)
            } else {
                EmptyStateView()
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddBookmarkView()
                .environmentObject(viewModel)
        }
        .onChange(of: viewModel.bookmarks) { _, newBookmarks in
            selectionManager.handleBookmarksChange(newBookmarks)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: UIConstants.MainWindow.minContentWidth, minHeight: UIConstants.MainWindow.minContentHeight)
        .onAppear {
            selectionManager.updateViewModel(viewModel)
        }
    }
}

private struct BookmarkRow: View {
    let bookmark: Bookmark

    var body: some View {
        HStack {
            BookmarkIconView(bookmark: bookmark, size: UIConstants.BookmarkRow.iconSize)

            VStack(alignment: .leading) {
                Text(bookmark.title)
                    .font(.headline)
                Text(bookmark.url)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, UIConstants.BookmarkRow.verticalPadding)
    }
}

struct DetailView: View {
    @EnvironmentObject var viewModel: BookmarkViewModel
    let bookmark: Bookmark
    @State private var isAnimating = false
    @State private var isDragging = false

    var iconView: some View {
        ImageDropHandler.createDropTargetView(
            bookmarkID: bookmark.id,
            isTargeted: $isDragging,
            onPreview: { image in
                IconPreviewManager.shared.showPreview(for: bookmark.id, image: image)
            },
            onComplete: { imageData in
                Task {
                    await viewModel.updateBookmarkIcon(bookmark: bookmark, iconData: imageData)
                }
            }
        ) {
            BookmarkIconView(bookmark: bookmark, size: UIConstants.BookmarkIcon.detailViewSize, showBackground: true)
                .opacity(isAnimating ? 1 : 0)
                .scaleEffect(isAnimating ? 1 : 0.8)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: UIConstants.Style.cornerRadius)
                        .fill(Color.secondary.opacity(UIConstants.Style.backgroundOpacity))
                        .overlay(
                            RoundedRectangle(cornerRadius: UIConstants.Style.cornerRadius)
                                .stroke(
                                    Color.secondary.opacity(isDragging ? 0.4 : 0.2),
                                    lineWidth: UIConstants.Style.borderWidth
                                )
                        )
                )
                .frame(
                    width: UIConstants.BookmarkIcon.detailContainerSize,
                    height: UIConstants.BookmarkIcon.detailContainerSize
                )
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: UIConstants.DetailView.elementSpacing) {
                Text(bookmark.title)
                    .font(.title)
                    .padding(.bottom, UIConstants.DetailView.titleBottomPadding)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : UIConstants.DetailView.entranceOffset)

                Text(bookmark.url)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : UIConstants.DetailView.entranceOffset)

                iconView

                Spacer()
            }
            .padding()
            .animation(
                .spring(response: UIConstants.DetailView.springResponse,
                        dampingFraction: UIConstants.DetailView.springDamping),
                value: isAnimating
            )
            .onAppear {
                withAnimation {
                    isAnimating = true
                }
            }
            .onDisappear {
                isAnimating = false
            }
        }
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: UIConstants.EmptyState.iconSize))
                .foregroundColor(.gray)
            Text("No Bookmark Selected")
                .font(.title2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
