//
//  CertificateMetadataViewController.swift
//  wallet
//
//  Created by Chris Downie on 4/4/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import UIKit
import Blockcerts

enum Section : Int {
    case information = 0, deleteCertificate
    case count
}

// Mark: - Custom UITableViewCells
private let MissingInformationCellReuseIdentifier = "MissingInformationTableViewCell"
private let InformationCellReuseIdentifier = "InformationTableViewCell"
private let DeleteCellReuseIdentifier = "DeleteTableViewCell"

class InformationTableViewCell : UITableViewCell {
    public var isTappable = false {
        didSet {
            if isTappable {
                selectionStyle = .default
                accessoryType = .disclosureIndicator
            } else {
                selectionStyle = .none
                accessoryType = .none
            }
        }
    }
    public var metadatum : Metadatum? {
        didSet {
            if let datum = metadatum {
                textLabel?.text = datum.label
                detailTextLabel?.text = datum.value
            }
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        guard let textLabel = self.textLabel, let detailTextLabel = detailTextLabel else {
            return
        }
        textLabel.textColor = .secondaryTextColor
        textLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        detailTextLabel.textColor = .primaryTextColor
        detailTextLabel.font = UIFont.preferredFont(forTextStyle: .body)
        detailTextLabel.numberOfLines = 2
        detailTextLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let views = [
            "titleLabel": textLabel,
            "valueLabel": detailTextLabel
        ]
        var constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[titleLabel][valueLabel]-|", options: .alignAllLeading, metrics: nil, views: views)
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "|-[titleLabel]-|", options: .alignAllLeading, metrics: nil, views: views))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "|-[valueLabel]-|", options: .alignAllLeading, metrics: nil, views: views))
        
        NSLayoutConstraint.activate(constraints)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateSelectabilityIfNeeded() {
        if let isTruncated = detailTextLabel?.isTruncated(), isTruncated {
            isTappable = true
            return
        }
        if let datum = metadatum, datum.type == .uri {
            isTappable = true
            return
        }
        isTappable = false
    }
}

class DeleteTableViewCell : UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier);
        
        textLabel?.textAlignment = .center
        textLabel?.textColor = .red
        textLabel?.text = NSLocalizedString("Delete Certificate", comment: "Action to delete a certificate in the metadata view.")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented");
    }
}

class MissingInformationTableViewCell : UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        textLabel?.text = NSLocalizedString("No additional information", comment: "Informational message about this certificate not having any metadata.")
        textLabel?.textColor = .disabledTextColor
        selectionStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CertificateMetadataViewController: UIViewController {
    public var delegate : CertificateViewControllerDelegate?
    fileprivate let certificate : Certificate
    private var tableView : UITableView!

    init(certificate: Certificate) {
        self.certificate = certificate
        tableView = nil
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView()
        
        let tableView : UITableView = UITableView(frame: .zero, style: .grouped);
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .baseColor

        tableView.register(InformationTableViewCell.self, forCellReuseIdentifier: InformationCellReuseIdentifier)
        tableView.register(DeleteTableViewCell.self, forCellReuseIdentifier: DeleteCellReuseIdentifier)
        tableView.register(MissingInformationTableViewCell.self, forCellReuseIdentifier: MissingInformationCellReuseIdentifier)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
        
        let constraints = [
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints);
        
        self.tableView = tableView
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = certificate.title
        
        let dismissButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(dismissSelf))
        navigationItem.leftBarButtonItem = dismissButton
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let path = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: path, animated: true)
        }
    }

    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    func promptForCertificateDeletion() {
        Logger.main.info("User has tapped the delete button on this certificate.")
        let certificateToDelete = certificate
        let title = NSLocalizedString("Be careful", comment: "Caution title presented when attempting to delete a certificate.")
        let message = NSLocalizedString("If you delete this certificate and don't have a backup, then you'll have to ask the issuer to send it to you again if you want to recover it. Are you sure you want to delete this certificate?", comment: "Explanation of the effects of deleting a certificate.")
        let delete = NSLocalizedString("Delete", comment: "Confirm delete action")
        let cancel = NSLocalizedString("Cancel", comment: "Cancel action")
        
        let prompt = UIAlertController(title: title, message: message, preferredStyle: .alert)
        prompt.addAction(UIAlertAction(title: delete, style: .destructive, handler: { [weak self] (_) in
            Logger.main.info("User has deleted certificate \(certificateToDelete.title) with id \(certificateToDelete.id)")
            self?.delegate?.delete(certificate: certificateToDelete)
            self?.dismissSelf();
        }))
        prompt.addAction(UIAlertAction(title: cancel, style: .cancel, handler: { [weak self] (_) in
            Logger.main.info("User canceled the deletion of the certificate.")
            if let selectedPath = self?.tableView.indexPathForSelectedRow {
                self?.tableView.deselectRow(at: selectedPath, animated: true)
            }
        }))
        
        present(prompt, animated: true, completion: nil)
    }
    
}

extension CertificateMetadataViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count.rawValue
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue:section) {
        case .some(.information):
            if certificate.metadata.visibleMetadata.isEmpty {
                // We'll still have a cell explaining why there's no metadata
                return 1
            }
            return certificate.metadata.visibleMetadata.count
        case .some(.deleteCertificate):
            return 1
        case .none:
            fallthrough
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == Section.information.rawValue {
            return NSLocalizedString("Information", comment: "Title for the metadata view, showing additional information on a certificate")
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Choose which cell to use
        var identifier = InformationCellReuseIdentifier
        if (indexPath.section == Section.deleteCertificate.rawValue) {
            identifier = DeleteCellReuseIdentifier
        } else if (indexPath.section == Section.information.rawValue && certificate.metadata.visibleMetadata.isEmpty) {
            identifier = MissingInformationCellReuseIdentifier
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)!
        
        // Load it up with data
        switch indexPath.section {
        case Section.information.rawValue:
            if !certificate.metadata.visibleMetadata.isEmpty {
                let metadatum = certificate.metadata.visibleMetadata[indexPath.row]
                if let infoCell = cell as? InformationTableViewCell {
                    infoCell.metadatum = metadatum
                }
            }
        case Section.deleteCertificate.rawValue:
            break
        default:
            // TODO: Is there a better way of failing here?
            cell.textLabel?.text = ""
        }
        
        return cell;
    }
    
}

extension CertificateMetadataViewController : UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }

        switch section {
        case .information:
            if let infoCell = tableView.cellForRow(at: indexPath) as? InformationTableViewCell,
                infoCell.isTappable {
                let metadatum = certificate.metadata.visibleMetadata[indexPath.row]
                if metadatum.type == .uri {
                    UIApplication.shared.open(URL(string:metadatum.value)!, options: [:]) { success in
                        OperationQueue.main.addOperation {
                            tableView.deselectRow(at: indexPath, animated: true)
                        }
                    }
                } else {
                    let detailView = MetadatumViewController()
                    detailView.metadatum = metadatum
                    self.navigationController?.pushViewController(detailView, animated: true)
                }
            } else {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        case .deleteCertificate:
            promptForCertificateDeletion();
        default:
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let infoCell = cell as? InformationTableViewCell {
            infoCell.updateSelectabilityIfNeeded()
        }
    }
}

// Mark: - Certificate MetadataDetailViewController
class MetadatumViewController : UIViewController {
    var metadatum : Metadatum? {
        didSet {
            title = metadatum?.label
            valueLabel?.text = metadatum?.value
        }
    }
    
    private var valueLabel : UILabel?
    
    override func loadView() {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .baseColor
        
        let contentView = UIView()
        let valueLabel = UILabel()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.numberOfLines = 0
        
        scrollView.addSubview(contentView)
        contentView.addSubview(valueLabel)
        
        let views = [
            "contentView": contentView,
            "valueLabel": valueLabel
        ]
        
        var constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[valueLabel]-|", options: .alignAllCenterX, metrics: nil, views: views)
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "|-[valueLabel]-|", options: .alignAllCenterY, metrics: nil, views: views))
        constraints.append(NSLayoutConstraint(item: contentView, attribute: .width, relatedBy: .equal, toItem: scrollView, attribute: .width, multiplier: 1, constant: 0))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|[contentView]|", options: .alignAllCenterX, metrics: nil, views: views))
        NSLayoutConstraint.activate(constraints)
        
        view = scrollView
        self.valueLabel = valueLabel
    }
    
    override func viewDidLoad() {
        valueLabel?.text = metadatum?.value
    }
    
}
