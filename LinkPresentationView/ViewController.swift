//
//  ViewController.swift
//  LinkPresentationView
//
//  Created by Toomas Vahter on 13.09.2019.
//  Copyright © 2019 Augmented Code. All rights reserved.
//

import LinkPresentation
import UIKit

final class ViewController: UIViewController {
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let linkView = LPLinkView(metadata: LPLinkMetadata())
        linkView.translatesAutoresizingMaskIntoConstraints = false
        stackView.insertArrangedSubview(linkView, at: 0)
        self.linkView = linkView
        textField.text = "https://www.apple.com"
    }

    private let metadataStorage = MetadataStorage()
    private lazy var metadataProvider = LPMetadataProvider()
    private weak var linkView: LPLinkView?
    
    @IBAction func loadPreview(_ sender: UIButton) {
        if let text = textField.text, let url = URL(string: text) {
            // Avoid fetching LPLinkMetadata every time and archieve it disk
            if let metadata = metadataStorage.metadata(for: url) {
                linkView?.metadata = metadata
                return
            }
            metadataProvider.startFetchingMetadata(for: url) { [weak self] (metadata, error) in
                if let error = error {
                    print(error)
                }
                else if let metadata = metadata {
                    DispatchQueue.main.async { [weak self] in
                        self?.metadataStorage.store(metadata)
                        self?.linkView?.metadata = metadata
                    }
                }
            }
        }
    }
}

struct MetadataStorage {
    private let storage = UserDefaults.standard
    
    func store(_ metadata: LPLinkMetadata) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: metadata, requiringSecureCoding: true)
            var metadatas = storage.dictionary(forKey: "Metadata") as? [String: Data] ?? [String: Data]()
            while metadatas.count > 10 {
                metadatas.removeValue(forKey: metadatas.randomElement()!.key)
            }
            metadatas[metadata.originalURL!.absoluteString] = data
            storage.set(metadatas, forKey: "Metadata")
        }
        catch {
            print("Failed storing metadata with error \(error as NSError)")
        }
    }
    
    func metadata(for url: URL) -> LPLinkMetadata? {
        guard let metadatas = storage.dictionary(forKey: "Metadata") as? [String: Data] else { return nil }
        guard let data = metadatas[url.absoluteString] else { return nil }
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: LPLinkMetadata.self, from: data)
        }
        catch {
            print("Failed to unarchive metadata with error \(error as NSError)")
            return nil
        }
    }
}
