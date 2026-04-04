import 'package:reddit_2_video/ffmpeg/file_type.dart';
import 'package:reddit_2_video/ffmpeg/fps.dart';
import 'package:test/test.dart';

void main() {
  group('FileType', () {
    test('matches known file types', () {
      expect(FileType.called('mp4'), FileType.mp4);
      expect(FileType.called('avi'), FileType.avi);
      expect(FileType.called('mov'), FileType.mov);
      expect(FileType.called('flv'), FileType.flv);
      expect(FileType.called('mkv'), isNull);
    });
  });

  group('FPS', () {
    test('matches known fps values and defaults unknown to 45', () {
      expect(FPS.fpsValue(15), FPS.fps15);
      expect(FPS.fpsValue(60), FPS.fps60);
      expect(FPS.fpsValue(999), FPS.fps45);
    });
  });
}
