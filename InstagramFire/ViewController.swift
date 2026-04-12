//
//  ViewController.swift
//  InstagramFire
//
//  Created by Павел Попов on 08.04.2026.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

final class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - UI
    
    private let plusPhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "plus_photo")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.tintColor = .clear
        return button
    }()
    
    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        return tf
    }()
    
    private let usernameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Username"
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        return tf
    }()
    
    private let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.isSecureTextEntry = true
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        return tf
    }()
    
    private let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        button.isEnabled = false
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupViews()
        setupTargets()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        plusPhotoButton.layer.cornerRadius = plusPhotoButton.frame.width / 2
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.addSubview(plusPhotoButton)
        
        plusPhotoButton.anchor(
            top: view.safeAreaLayoutGuide.topAnchor,
            left: nil,
            bottom: nil,
            right: nil,
            paddingTop: 40,
            paddingLeft: 0,
            paddingBottom: 0,
            paddingRight: 0,
            width: 140,
            height: 140
        )
        plusPhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        let stackView = UIStackView(arrangedSubviews: [
            emailTextField,
            usernameTextField,
            passwordTextField,
            signUpButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        
        view.addSubview(stackView)
        stackView.anchor(
            top: plusPhotoButton.bottomAnchor,
            left: view.leftAnchor,
            bottom: nil,
            right: view.rightAnchor,
            paddingTop: 20,
            paddingLeft: 40,
            paddingBottom: 0,
            paddingRight: 40,
            width: 0,
            height: 200
        )
    }
    
    private func setupTargets() {
        plusPhotoButton.addTarget(self, action: #selector(handlePlusPhoto), for: .touchUpInside)
        signUpButton.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        
        emailTextField.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        usernameTextField.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
    }
    
    // MARK: - Actions
    
    @objc private func handlePlusPhoto() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true)
    }
    
    @objc private func handleTextInputChange() {
        let isFormValid =
            !(emailTextField.text ?? "").isEmpty &&
            !(usernameTextField.text ?? "").isEmpty &&
            !(passwordTextField.text ?? "").isEmpty
        
        signUpButton.isEnabled = isFormValid
        signUpButton.backgroundColor = isFormValid
            ? UIColor.rgb(red: 17, green: 154, blue: 237)
            : UIColor.rgb(red: 149, green: 204, blue: 244)
    }
    
    @objc private func handleSignUp() {
        guard let email = emailTextField.text, !email.isEmpty else { return }
        guard let username = usernameTextField.text, !username.isEmpty else { return }
        guard let password = passwordTextField.text, !password.isEmpty else { return }
        guard let image = plusPhotoButton.imageView?.image else {
            print("Profile image not selected")
            return
        }
        guard let uploadData = image.jpegData(compressionQuality: 0.3) else {
            print("Failed to convert image to JPEG data")
            return
        }
        
        signUpButton.isEnabled = false
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Failed to create user:", error.localizedDescription)
                self.signUpButton.isEnabled = true
                return
            }
            
            guard let uid = authResult?.user.uid else {
                print("Failed to get uid")
                self.signUpButton.isEnabled = true
                return
            }
            
            let filename = UUID().uuidString
            let storageRef = Storage.storage().reference().child("profile_images").child(filename)
            
            storageRef.putData(uploadData, metadata: nil) { _, error in
                if let error = error {
                    print("Failed to upload profile image:", error.localizedDescription)
                    self.signUpButton.isEnabled = true
                    return
                }
                
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("Failed to fetch download URL:", error.localizedDescription)
                        self.signUpButton.isEnabled = true
                        return
                    }
                    
                    guard let profileImageUrl = url?.absoluteString else {
                        print("Download URL is nil")
                        self.signUpButton.isEnabled = true
                        return
                    }
                    
                    let values: [String: Any] = [
                        "username": username,
                        "profileImageUrl": profileImageUrl
                    ]
                    
                    Database.database().reference()
                        .child("users")
                        .child(uid)
                        .updateChildValues(values) { error, _ in
                            if let error = error {
                                print("Failed to save user info into db:", error.localizedDescription)
                                self.signUpButton.isEnabled = true
                                return
                            }
                            
                            print("Successfully created user:", uid)
                            print("Successfully uploaded profile image:", profileImageUrl)
                            print("Successfully saved user info to db")
                        }
                }
            }
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let selectedImage = (info[.editedImage] ?? info[.originalImage]) as? UIImage
        
        if let image = selectedImage {
            plusPhotoButton.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
            plusPhotoButton.imageView?.contentMode = .scaleAspectFill
            plusPhotoButton.layer.masksToBounds = true
            plusPhotoButton.layer.borderColor = UIColor.black.cgColor
            plusPhotoButton.layer.borderWidth = 3
        }
        
        dismiss(animated: true)
    }
}

// MARK: - Extensions

extension UIView {
    func anchor(
        top: NSLayoutYAxisAnchor?,
        left: NSLayoutXAxisAnchor?,
        bottom: NSLayoutYAxisAnchor?,
        right: NSLayoutXAxisAnchor?,
        paddingTop: CGFloat,
        paddingLeft: CGFloat,
        paddingBottom: CGFloat,
        paddingRight: CGFloat,
        width: CGFloat,
        height: CGFloat
    ) {
        translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top {
            topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
        }
        
        if let left = left {
            leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
        }
        
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true
        }
        
        if let right = right {
            rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
        }
        
        if width != 0 {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        
        if height != 0 {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }
}
