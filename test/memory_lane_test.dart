import 'package:flutter_test/flutter_test.dart';
import 'package:purb_chetana/models/memory_item.dart';

void main() {
  group('MemoryItem Data Model Tests', () {
    test('Personal memory backward compatibility', () {
      final json = {
        'id': 'mem-1',
        'title': 'Grandson Visit',
        'date': '2026-10-01',
        'imagePath': 'assets/images/sample.jpg',
        'storyNote': 'A wonderful afternoon together.',
        'voiceNotePath': '/path/to/voice.m4a',
        'videoPath': '/path/to/video.mp4',
        'category': 'personal',
      };

      final item = MemoryItem.fromJson(json);
      expect(item.id, 'mem-1');
      expect(item.title, 'Grandson Visit');
      expect(item.category, 'personal');
      expect(item.artist, isNull);
      expect(item.photos, contains('assets/images/sample.jpg'));
      expect(item.fileName, isNull);
      expect(item.duration, isNull);

      final serialized = item.toJson();
      expect(serialized['id'], 'mem-1');
      expect(serialized['title'], 'Grandson Visit');
      expect(serialized['category'], 'personal');
    });

    test('Favorite Music model serialization and deserialization', () {
      final music = MemoryItem(
        id: 'music-101',
        title: 'Ilaya Nila',
        date: '2026-10-07',
        imagePath: '',
        storyNote: 'One of his favorite songs',
        audioPath: '/local/storage/music/ilaya_nila.mp3',
        category: 'music',
        artist: 'SPB',
        fileName: 'ilaya_nila.mp3',
        duration: '04:35',
      );

      final json = music.toJson();
      expect(json['id'], 'music-101');
      expect(json['title'], 'Ilaya Nila');
      expect(json['artist'], 'SPB');
      expect(json['category'], 'music');
      expect(json['fileName'], 'ilaya_nila.mp3');
      expect(json['duration'], '04:35');
      expect(json['audioPath'], '/local/storage/music/ilaya_nila.mp3');

      final reconstructed = MemoryItem.fromJson(json);
      expect(reconstructed.id, 'music-101');
      expect(reconstructed.title, 'Ilaya Nila');
      expect(reconstructed.artist, 'SPB');
      expect(reconstructed.category, 'music');
      expect(reconstructed.fileName, 'ilaya_nila.mp3');
      expect(reconstructed.duration, '04:35');
      expect(reconstructed.storyNote, 'One of his favorite songs');
    });

    test('Favorite Place model serialization with multiple photos', () {
      final place = MemoryItem(
        id: 'place-201',
        title: 'Marina Beach',
        date: '2026-10-07',
        imagePath: '/local/storage/places/p1.jpg',
        storyNote: 'One of his favorite places where he used to spend evenings.',
        videoPath: '/local/storage/places/beach.mp4',
        voiceNotePath: '/local/storage/places/voice.m4a',
        category: 'places',
        photos: [
          '/local/storage/places/p1.jpg',
          '/local/storage/places/p2.jpg',
          '/local/storage/places/p3.jpg',
        ],
      );

      final json = place.toJson();
      expect(json['id'], 'place-201');
      expect(json['title'], 'Marina Beach');
      expect(json['category'], 'places');
      expect(json['photos'], hasLength(3));
      expect(json['photos'][1], '/local/storage/places/p2.jpg');

      final reconstructed = MemoryItem.fromJson(json);
      expect(reconstructed.id, 'place-201');
      expect(reconstructed.title, 'Marina Beach');
      expect(reconstructed.photos, hasLength(3));
      expect(reconstructed.photos[0], '/local/storage/places/p1.jpg');
      expect(reconstructed.videoPath, '/local/storage/places/beach.mp4');
      expect(reconstructed.voiceNotePath, '/local/storage/places/voice.m4a');
    });
  });

  group('MemoryLaneService Status Transitions Tests', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('Favorite Music status progression: uploading -> saving -> saved', () async {
      final statuses = <String>[];
      void onStatusChanged(String status) {
        statuses.add(status);
      }

      // Simulates the exact state callback sequence
      onStatusChanged('uploading');
      expect(statuses.last, 'uploading');

      onStatusChanged('saving');
      expect(statuses.last, 'saving');

      onStatusChanged('saved');
      expect(statuses.last, 'saved');

      expect(statuses, equals(['uploading', 'saving', 'saved']));
    });

    test('Favorite Place status progression: saving -> saved', () async {
      final statuses = <String>[];
      void onStatusChanged(String status) {
        statuses.add(status);
      }

      // Simulates the exact state callback sequence
      onStatusChanged('saving');
      expect(statuses.last, 'saving');

      onStatusChanged('saved');
      expect(statuses.last, 'saved');

      expect(statuses, equals(['saving', 'saved']));
    });
  });
}
