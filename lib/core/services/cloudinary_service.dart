import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // Replace with your actual Cloud Name and Upload Preset
  // The user provided: 8JhlxA3Lmc8WtE6bqSZkqMcUtYM (Assuming this is Upload Preset)
  static const String _cloudName = 'deu0oe2uh';
  static const String _uploadPreset = 'dfaidcpy';

  final CloudinaryPublic _cloudinary;
  final ImagePicker _picker;

  CloudinaryService()
    : _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false),
      _picker = ImagePicker();

  Future<String?> pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image == null) return null;

      final CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl;
    } on CloudinaryException catch (e) {
      throw Exception("Cloudinary Upload Error: ${e.message}");
    } catch (e) {
      throw Exception("Image Upload Failed: $e");
    }
  }
}
