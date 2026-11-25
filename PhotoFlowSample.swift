import PhotosUI
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {}

@objc(PhotoFlowSceneDelegate)
final class PhotoFlowSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = PhotoFlowViewController()
        window.makeKeyAndVisible()
        self.window = window
    }
}

final class PhotoFlowViewController: UIViewController, PHPickerViewControllerDelegate {
    private var original: UIImage?
    private let resultFile = URL.documentsDirectory.appending(path: "fixture-result.png")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        showHome()
    }

    private func showHome() {
        var items: [UIView] = [button("Choose photo", id: "pick-photo", action: #selector(pickPhoto))]
        if let original {
            items.append(imageView(original, id: "selected-photo-preview"))
            items.append(button("Generate test result", id: "generate", action: #selector(generate)))
        }
        items.append(button("Open gallery", id: "open-gallery", action: #selector(openGallery)))
        show(items)
    }

    @objc private func pickPhoto() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        results.first?.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage,
                  image.cgImage?.width == 160,
                  image.cgImage?.height == 160 else { return }
            DispatchQueue.main.async {
                self?.original = image
                self?.showHome()
            }
        }
    }

    @objc private func generate() {
        guard let original else { return }
        let result = UIGraphicsImageRenderer(size: original.size).image { context in
            original.draw(at: .zero)
            context.cgContext.setFillColor(UIColor.systemBlue.cgColor)
            context.cgContext.fill(CGRect(x: 0, y: 0, width: original.size.width, height: max(original.size.height / 10, 1)))
        }
        guard let png = result.pngData() else { return }
        do {
            try png.write(to: resultFile, options: .atomic)
            show([imageView(result, id: "generated-result")])
        } catch {
            show([UILabel(frame: .zero)])
        }
    }

    @objc private func openGallery() {
        if FileManager.default.fileExists(atPath: resultFile.path) {
            show([button("Test fixture result", id: "gallery-result-test-fixture", action: #selector(openResult))])
        }
    }

    @objc private func openResult() {
        if let result = UIImage(contentsOfFile: resultFile.path) {
            show([imageView(result, id: "reopened-result")])
        }
    }

    private func button(_ title: String, id: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.accessibilityIdentifier = id
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func imageView(_ image: UIImage, id: String) -> UIImageView {
        let view = UIImageView(image: image)
        view.contentMode = .scaleAspectFit
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Fixture photo"
        view.accessibilityIdentifier = id
        view.widthAnchor.constraint(equalToConstant: 140).isActive = true
        view.heightAnchor.constraint(equalToConstant: 140).isActive = true
        return view
    }

    private func show(_ items: [UIView]) {
        view.subviews.forEach { $0.removeFromSuperview() }
        let stack = UIStackView(arrangedSubviews: items)
        stack.axis = .vertical
        stack.spacing = 22
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
