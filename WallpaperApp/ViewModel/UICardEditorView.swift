//
//  UICardEditorView.swift
//  WallpaperApp
//
//  Created by macmini on 2026/7/7.
//

import UIKit
import SwiftUI

class UICardEditorView: UIView {
    
    // 線性排版容器（負責文字與圖片段落）
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()
    
    // 圖片點擊回傳閉包
    var onImagePickRequested: ((UUID) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBaseView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBaseView() {
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.masksToBounds = true
        
        addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 設定線性排版的約束（置頂，左右留邊記）
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - 功能 1 & 2: 新增文字與圖片段落
    func updateComponents(_ components: [CardComponentType]) {
        // 比對現有視圖，決定是否需要重新構建（避免重複刷新遺失輸入焦點）
        let currentViews = contentStackView.arrangedSubviews.compactMap { $0 as? ComponentContainerView }
        
        if currentViews.count != components.count {
            // 清空重新加入
            contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            for (index, component) in components.enumerated() {
                let container = ComponentContainerView(component: component, index: index, totalCount: components.count)
                container.delegate = self
                contentStackView.addArrangedSubview(container)
            }
        } else {
            // 更新現有視圖內容
            for (index, view) in currentViews.enumerated() {
                view.updateIndex(index, totalCount: components.count)
                if case .image(_, let img) = components[index] {
                    view.updateImage(img)
                }
            }
        }
    }
    
    // MARK: - 功能 3: 新增貼紙（自由擺放與拖曳）
    func addSticker(named name: String) {
        let stickerImageView = UIImageView(image: UIImage(systemName: name))
        stickerImageView.tintColor = .systemOrange
        stickerImageView.contentMode = .scaleAspectFit
        stickerImageView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        stickerImageView.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        stickerImageView.isUserInteractionEnabled = true
        
        // 加入拖曳手勢
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleStickerPan(_:)))
        stickerImageView.addGestureRecognizer(panGesture)
        
        addSubview(stickerImageView)
    }
    
    @objc private func handleStickerPan(_ gesture: UIPanGestureRecognizer) {
        guard let sticker = gesture.view else { return }
        let translation = gesture.translation(in: self)
        
        sticker.center = CGPoint(x: sticker.center.x + translation.x, y: sticker.center.y + translation.y)
        gesture.setTranslation(.zero, in: self)
    }
    
    // MARK: - 功能 4: 輸出圖檔
    func renderToImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { context in
            layer.render(in: context.cgContext)
        }
    }
}

// MARK: - 內部元件外殼（處理刪除小叉叉、上下移動功能）
protocol ComponentContainerViewDelegate: AnyObject {
    func didRequestDelete(at index: Int)
    func didRequestMoveUp(at index: Int)
    func didRequestMoveDown(at index: Int)
}

class ComponentContainerView: UIView, UITextViewDelegate {
    let component: CardComponentType
    private var index: Int
    private var totalCount: Int
    weak var delegate: ComponentContainerViewDelegate?
    
    private let contentView: UIView = UIView()
    private let deleteButton = UIButton(type: .system)
    private let moveUpButton = UIButton(type: .system)
    private let moveDownButton = UIButton(type: .system)
    private var imageView: UIImageView?
    
    init(component: CardComponentType, index: Int, totalCount: Int) {
        self.component = component
        self.index = index
        self.totalCount = totalCount
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) { fatalError("init") }
    
    private func setupView() {
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // 依據型態放入主要內容
        switch component {
        case .text(_, let text):
            let textView = UITextView()
            textView.text = text.isEmpty ? "請輸入文字..." : text
            textView.font = .systemFont(ofSize: 16)
            textView.isScrollEnabled = false
            textView.layer.borderColor = UIColor.lightGray.cgColor
            textView.layer.borderWidth = 0.5
            textView.layer.cornerRadius = 4
            textView.delegate = self
            
            contentView.addSubview(textView)
            textView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
                textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
                textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
                textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
            ])
            
        case .image:
            let imgView = UIImageView()
            imgView.backgroundColor = UIColor.systemGray6
            imgView.contentMode = .scaleAspectFill
            imgView.layer.cornerRadius = 6
            imgView.clipsToBounds = true
            imgView.isUserInteractionEnabled = true
            
            // 提示點擊上傳的標籤
            let hintLabel = UILabel()
            hintLabel.text = "點擊上傳圖片"
            hintLabel.textColor = .lightGray
            hintLabel.font = .systemFont(ofSize: 14)
            imgView.addSubview(hintLabel)
            hintLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hintLabel.centerXAnchor.constraint(equalTo: imgView.centerXAnchor),
                hintLabel.centerYAnchor.constraint(equalTo: imgView.centerYAnchor)
            ])
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
            imgView.addGestureRecognizer(tap)
            
            contentView.addSubview(imgView)
            imgView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imgView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
                imgView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
                imgView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
                imgView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
                imgView.heightAnchor.constraint(equalToConstant: 150)
            ])
            self.imageView = imgView
        }
        
        // 設定右上/右下按鈕
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.addTarget(self, action: #selector(deleteAction), for: .touchUpInside)
        
        moveUpButton.setImage(UIImage(systemName: "chevron.up.circle.fill"), for: .normal)
        moveDownButton.setImage(UIImage(systemName: "chevron.down.circle.fill"), for: .normal)
        moveUpButton.addTarget(self, action: #selector(moveUpAction), for: .touchUpInside)
        moveDownButton.addTarget(self, action: #selector(moveDownAction), for: .touchUpInside)
        
        addSubview(deleteButton)
        addSubview(moveUpButton)
        addSubview(moveDownButton)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        moveUpButton.translatesAutoresizingMaskIntoConstraints = false
        moveDownButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            // 右下角小叉叉
            deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 2),
            deleteButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 2),
            deleteButton.widthAnchor.constraint(equalToConstant: 24),
            deleteButton.heightAnchor.constraint(equalToConstant: 24),
            
            // 右上角移動符號 (上/下按鈕組合)
            moveUpButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 2),
            moveUpButton.topAnchor.constraint(equalTo: topAnchor, constant: -2),
            moveUpButton.widthAnchor.constraint(equalToConstant: 24),
            moveUpButton.heightAnchor.constraint(equalToConstant: 24),
            
            moveDownButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 2),
            moveDownButton.topAnchor.constraint(equalTo: moveUpButton.bottomAnchor, constant: 2),
            moveDownButton.widthAnchor.constraint(equalToConstant: 24),
            moveDownButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        updateButtonVisibility()
    }
    
    func updateIndex(_ index: Int, totalCount: Int) {
        self.index = index
        self.totalCount = totalCount
        updateButtonVisibility()
    }
    
    func updateImage(_ img: UIImage?) {
        if let img = img {
            imageView?.image = img
            imageView?.subviews.first?.isHidden = true // 隱藏提示字
        }
    }
    
    private func updateButtonVisibility() {
        moveUpButton.isHidden = (index == 0)
        moveDownButton.isHidden = (index == totalCount - 1)
    }
    
    @objc private func deleteAction() { delegate?.didRequestDelete(at: index) }
    @objc private func moveUpAction() { delegate?.didRequestMoveUp(at: index) }
    @objc private func moveDownAction() { delegate?.didRequestMoveDown(at: index) }
    @objc private func imageTapped() {
        if let parent = superview?.superview as? UICardEditorView {
            parent.onImagePickRequested?(component.id)
        }
    }
    
    // 清除 TextView 預設文字
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "請輸入文字..." { textView.text = "" }
    }
}

// 實作控制項的搬移與刪除代理
extension UICardEditorView: ComponentContainerViewDelegate {
    func didRequestDelete(at index: Int) {
        NotificationCenter.default.post(name: .cardComponentDeleted, object: nil, userInfo: ["index": index])
    }
    func didRequestMoveUp(at index: Int) {
        NotificationCenter.default.post(name: .cardComponentMoved, object: nil, userInfo: ["from": index, "to": index - 1])
    }
    func didRequestMoveDown(at index: Int) {
        NotificationCenter.default.post(name: .cardComponentMoved, object: nil, userInfo: ["from": index, "to": index + 1])
    }
}

// 通知擴充
extension Notification.Name {
    static let cardComponentDeleted = Notification.Name("cardComponentDeleted")
    static let cardComponentMoved = Notification.Name("cardComponentMoved")
}







//MARK: - CardEditorRepresentable


struct CardEditorRepresentable: UIViewRepresentable {
    @Binding var components: [CardComponentType]
    @Binding var stickerTrigger: String? // 用來監聽新貼紙的新增
    var onImagePickRequested: (UUID) -> Void
    var onRendererAvailable: (UICardEditorView) -> Void
    
    func makeUIView(context: Context) -> UICardEditorView {
        let view = UICardEditorView()
        view.onImagePickRequested = onImagePickRequested
        onRendererAvailable(view) // 將實體傳回給主畫面供導出圖片使用
        
        // 監聽來自 UIKit 的排版異動
        NotificationCenter.default.addObserver(forName: .cardComponentDeleted, object: nil, queue: .main) { notification in
            if let index = notification.userInfo?["index"] as? Int, components.indices.contains(index) {
                components.remove(at: index)
            }
        }
        
        NotificationCenter.default.addObserver(forName: .cardComponentMoved, object: nil, queue: .main) { notification in
            if let from = notification.userInfo?["from"] as? Int,
               let to = notification.userInfo?["to"] as? Int,
               components.indices.contains(from), components.indices.contains(to) {
                components.swapAt(from, to)
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UICardEditorView, context: Context) {
        uiView.updateComponents(components)
        
        // 檢查是否有要新增的貼紙
        if let stickerName = stickerTrigger {
            uiView.addSticker(named: stickerName)
            DispatchQueue.main.async {
                self.stickerTrigger = nil // 觸發後清空
            }
        }
    }
}


// MARK: - 照片選擇器橋接
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage { parent.image = image }
            picker.dismiss(animated: true)
        }
    }
}

// 分享視圖橋接
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
