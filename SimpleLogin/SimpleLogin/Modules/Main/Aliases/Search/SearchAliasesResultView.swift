//
//  SearchAliasesResultView.swift
//  SimpleLogin
//
//  Created by Thanh-Nhon Nguyen on 05/02/2022.
//

import Combine
import SimpleLoginPackage
import SwiftUI

struct SearchAliasesResultView: View {
    @ObservedObject var viewModel: SearchAliasesViewModel
    @State private var showingUpdatingAlert = false
    @State private var copiedEmail: String?
    var onSelect: (Alias) -> Void
    var onSendMail: (Alias) -> Void
    var onUpdate: (Alias) -> Void
    var onDelete: (Alias) -> Void

    var body: some View {
        let showingCopiedEmailAlert = Binding<Bool>(get: {
            copiedEmail != nil
        }, set: { isShowing in
            if !isShowing {
                copiedEmail = nil
            }
        })

        List {
            if viewModel.aliases.isEmpty,
               !viewModel.isLoading,
               let lastSearchTerm = viewModel.lastSearchTerm {
                Text("No results for \"\(lastSearchTerm)\"")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.aliases, id: \.id) { alias in
                    AliasCompactView(
                        alias: alias,
                        onCopy: {
                            Vibration.soft.vibrate()
                            copiedEmail = alias.email
                            UIPasteboard.general.string = alias.email
                        },
                        onSendMail: {
                            onSendMail(alias)
                        },
                        onToggle: {
                            viewModel.toggle(alias: alias)
                        },
                        onPin: {
                            viewModel.update(alias: alias, option: .pinned(true))
                        },
                        onUnpin: {
                            viewModel.update(alias: alias, option: .pinned(false))
                        },
                        onDelete: {
                            viewModel.delete(alias: alias)
                        })
                        .padding(.horizontal, 4)
                        .onTapGesture {
                            onSelect(alias)
                        }
                        .onAppear {
                            viewModel.getMoreAliasesIfNeed(currentAlias: alias)
                        }
                }

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
        }
        .listStyle(.plain)
        .offlineLabelled(reachable: viewModel.reachabilityObserver.reachable)
        .simultaneousGesture(
            DragGesture().onChanged { _ in
                UIApplication.shared.endEditing()
            }
        )
        .onReceive(Just(viewModel.isUpdating)) { isUpdating in
            showingUpdatingAlert = isUpdating
        }
        .onReceive(Just(viewModel.updatedAlias)) { updatedAlias in
            if let updatedAlias = updatedAlias {
                onUpdate(updatedAlias)
            }
        }
        .onReceive(Just(viewModel.deletedAlias)) { deletedAlias in
            if let deletedAlias = deletedAlias {
                onDelete(deletedAlias)
            }
        }
        .alertToastLoading(isPresenting: $showingUpdatingAlert)
        .alertToastCopyMessage(isPresenting: showingCopiedEmailAlert, message: copiedEmail)
        .alertToastError($viewModel.error)
    }
}
