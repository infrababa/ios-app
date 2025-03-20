//
//  DomainDetailView.swift
//  SimpleLogin
//
//  Created by Thanh-Nhon Nguyen on 14/01/2022.
//

import SimpleLoginPackage
import SwiftUI

struct DomainDetailView: View {
    @StateObject private var viewModel: DomainDetailViewModel

    init(domain: CustomDomain,
         session: Session,
         onUpdateDomains: @escaping ([CustomDomain]) -> Void) {
        _viewModel = StateObject(wrappedValue: .init(domain: domain,
                                                     session: session,
                                                     onUpdateDomains: onUpdateDomains))
    }

    var body: some View {
        List {
            DomainNameSection(domain: viewModel.domain)
            CatchAllSection(viewModel: viewModel)
            DefaultDisplayNameSection(viewModel: viewModel)
            RandomPrefixSection(viewModel: viewModel)
            DeletedAliasesSection(viewModel: viewModel)
        }
        .listStyle(.insetGrouped)
        .ignoresSafeArea(.keyboard)
        .navigationTitle(viewModel.domain.domainName)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.refresh() }
        .alertToastLoading(isPresenting: $viewModel.isUpdating)
        .alertToastError($viewModel.error)
    }
}

// MARK: - Sections
private struct DomainNameSection: View {
    let domain: CustomDomain

    var body: some View {
        Section {
            VStack(alignment: .leading) {
                Text(domain.domainName)
                    .font(.title)
                Text("\(domain.aliasCount) alias(es)")
                    .font(.footnote)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct CatchAllSection: View {
    @ObservedObject var viewModel: DomainDetailViewModel

    var body: some View {
        let domain = viewModel.domain
        Section(content: {
            Toggle("Catch all", isOn: $viewModel.catchAll.animation())
                .toggleStyle(SwitchToggleStyle(tint: .slPurple))
            if viewModel.catchAll {
                VStack(alignment: .leading) {
                    Text("Default mailboxes".uppercased())
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    NavigationLink(destination: {
                        EditMailboxesView(viewModel: viewModel)
                    }, label: {
                        Text(domain.mailboxes.map { $0.email }.joined(separator: "\n"))
                    })
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }, header: {
            Text("Auto create/on the fly alias")
        }, footer: {
            // swiftlint:disable:next line_length
            Text("Simply use anything@\(domain.domainName) next time you need an alias: it'll be automatically created the first time it receives an email. To have more fine-grained control, you can also define auto create rules.")
        })
    }
}

private struct EditMailboxesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DomainDetailViewModel
    @State private var selectedIds: [Int] = []

    init(viewModel: DomainDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
        _selectedIds = .init(initialValue: viewModel.domain.mailboxes.map { $0.id })
    }

    var body: some View {
        Form {
            Section(content: {
                ForEach(viewModel.mailboxes, id: \.id) { mailbox in
                    HStack {
                        Text(mailbox.email)
//                            .foregroundColor(mailbox.verified ? .primary : .secondary)
                        Spacer()
                        if selectedIds.contains(mailbox.id) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
//                        if !mailbox.verified {
//                            BorderedText.unverified
//                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
//                        guard mailbox.verified else { return }
                        if selectedIds.contains(mailbox.id) && selectedIds.count > 1 {
                            selectedIds.removeAll { $0 == mailbox.id }
                        } else if !selectedIds.contains(mailbox.id) {
                            selectedIds.append(mailbox.id)
                        }
                    }
                }
            }, header: {
                if !viewModel.mailboxes.isEmpty {
                    Text("Default mailboxes")
                }
            }, footer: {
                if !viewModel.mailboxes.isEmpty {
                    PrimaryButton(title: "Save") {
                        viewModel.update(option: .mailboxIds(selectedIds))
                    }
                    .padding(.vertical)
                }
            })
        }
        .navigationBarTitle(viewModel.domain.domainName)
        .task { await viewModel.getMailboxes() }
        .onReceive(viewModel.$isUpdated.dropFirst()) { isUpdated in
            if isUpdated {
                dismiss()
                viewModel.handledIsUpdatedBoolean()
            }
        }
        .alertToastLoading(isPresenting: $viewModel.isUpdating)
        .alertToastLoading(isPresenting: $viewModel.isLoadingMailboxes)
        .alertToastError($viewModel.error)
    }
}

private struct DefaultDisplayNameSection: View {
    @ObservedObject var viewModel: DomainDetailViewModel
    @State private var showingEditAlert = false

    var body: some View {
        Section(content: {
            Text(viewModel.domain.name ?? "")
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .contentShape(Rectangle())
                .textFieldAlert(isPresented: $showingEditAlert, config: editDisplayNameConfig)
                .onTapGesture {
                    showingEditAlert = true
                }
        }, header: {
            Text("Default display name")
        }, footer: {
            // swiftlint:disable:next line_length
            Text("Default display name for aliases created with \(viewModel.domain.domainName) unless overwritten by the alias display name")
        })
    }

    private var editDisplayNameConfig: TextFieldAlertConfig {
        TextFieldAlertConfig(title: "Default display name",
                             text: viewModel.domain.name,
                             placeholder: "Ex: John Doe",
                             autocapitalizationType: .words,
                             actionTitle: "Save") { newDisplayName in
            viewModel.update(option: .name(newDisplayName))
        }
    }
}

private struct EditDisplayNameView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DomainDetailViewModel
    @State private var displayName = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Display name"),
                        footer: Text("You can remove display name by leaving this field blank")) {
                    if #available(iOS 15, *) {
                        AutoFocusTextField(text: $displayName)
                            .modifier(ClearButtonModeModifier(mode: .whileEditing))
                    } else {
                        TextField("", text: $displayName)
                            .labelsHidden()
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                            .modifier(ClearButtonModeModifier(mode: .whileEditing))
                    }
                }
            }
            .navigationTitle(viewModel.domain.domainName)
            .navigationBarItems(leading: cancelButton, trailing: doneButton)
        }
        .accentColor(.slPurple)
        .onAppear {
            displayName = viewModel.domain.name ?? ""
        }
        .onReceive(viewModel.$isUpdated.dropFirst()) { isUpdated in
            if isUpdated {
                dismiss()
                viewModel.handledIsUpdatedBoolean()
            }
        }
        .alertToastLoading(isPresenting: $viewModel.isUpdating)
        .alertToastError($viewModel.error)
    }

    private var cancelButton: some View {
        Button(action: dismiss.callAsFunction) {
            Text("Cancel")
        }
    }

    private var doneButton: some View {
        Button(action: {
            viewModel.update(option: .name(displayName.isEmpty ? nil : displayName))
        }, label: {
            Text("Done")
        })
    }
}

private struct RandomPrefixSection: View {
    @ObservedObject var viewModel: DomainDetailViewModel

    var body: some View {
        Section(content: {
            Toggle("Enabled", isOn: $viewModel.randomPrefixGeneration)
                .toggleStyle(SwitchToggleStyle(tint: .slPurple))
        }, header: {
            Text("Random prefix generation")
        }, footer: {
            Text("Add a random prefix for this domain when creating new aliases")
        })
    }
}

private struct DeletedAliasesSection: View {
    let viewModel: DomainDetailViewModel

    var body: some View {
        Section {
            NavigationLink(destination: {
                DeletedAliasesView(session: viewModel.session, domain: viewModel.domain)
            }, label: {
                Text("Deleted aliases")
            })
        }
    }
}
