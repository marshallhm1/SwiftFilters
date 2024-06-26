import SwiftUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

// Define additional filters using their CIFilter names
enum CustomFilter: String, CaseIterable {
    case Chrome = "CIPhotoEffectChrome"
    case Fade = "CIPhotoEffectFade"
    case Instant = "CIPhotoEffectInstant"
    case Mono = "CIPhotoEffectMono"
    case Noir = "CIPhotoEffectNoir"
    case Process = "CIPhotoEffectProcess"
    case Tonal = "CIPhotoEffectTonal"
    case Transfer = "CIPhotoEffectTransfer"
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        @Binding var image: UIImage?

        init(image: Binding<UIImage?>) {
            _image = image
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                image = uiImage
            }
            picker.dismiss(animated: true, completion: nil)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true, completion: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(image: $image)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No need to update the UIImagePickerController
    }
}

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingFilterSheet = false
    @State private var selectedFilter: CustomFilter? // Optional selected filter

    let context = CIContext()

    var body: some View {
        NavigationView {
            VStack {
                if let image = processedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .padding()
                }

                Button("Select an Image") {
                    showingImagePicker = true
                }
                .padding()
                .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                    ImagePicker(image: $selectedImage)
                }

                Button("Apply Filter") {
                    showingFilterSheet = true
                }
                .padding()

                Spacer()
            }
            .navigationTitle("Image Filter")
            .actionSheet(isPresented: $showingFilterSheet) {
                ActionSheet(title: Text("Select a Filter"), buttons: filterButtons)
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button("Save") {
                        if let image = processedImage {
                            saveImage(image)
                        }
                    }
                }
            }
        }
    }

    private var filterButtons: [ActionSheet.Button] {
        var buttons = [ActionSheet.Button]()
        
        // Add buttons for each filter in the enum
        for filter in CustomFilter.allCases {
            buttons.append(.default(Text(filter.rawValue)) {
                selectedFilter = filter
                applyFilter()
            })
        }
        
        // Add cancel button
        buttons.append(.cancel())
        
        return buttons
    }

    func loadImage() {
        guard let inputImage = selectedImage else { return }
        let beginImage = CIImage(image: inputImage)

        // Apply selected filter if it exists
        if let selectedFilter = selectedFilter, let filter = CIFilter(name: selectedFilter.rawValue) {
            filter.setValue(beginImage, forKey: kCIInputImageKey)

            if let outputImage = filter.outputImage {
                // Maintain original image resolution
                let scaledImage = scaleImage(outputImage, to: inputImage.size)
                if let cgimg = context.createCGImage(scaledImage, from: scaledImage.extent) {
                    processedImage = UIImage(cgImage: cgimg)
                }
            }
        } else {
            // No filter selected, just show the original image
            processedImage = inputImage
        }
    }

    func applyFilter() {
        loadImage() // Reload image to apply selected filter
    }

    func saveImage(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    func scaleImage(_ image: CIImage, to size: CGSize) -> CIImage {
        let scale = CGAffineTransform(scaleX: size.width / image.extent.size.width, y: size.height / image.extent.size.height)
        return image.transformed(by: scale)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
