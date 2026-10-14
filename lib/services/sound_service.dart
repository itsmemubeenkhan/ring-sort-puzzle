/// Sound effects service.
///
/// NOTE: Audio playback via the audioplayers plugin was removed because the
/// plugin's Android build could not be resolved in this offline build
/// environment. All methods are safe no-ops. To re-enable sound, add
/// `audioplayers` back to pubspec.yaml and restore the tone synthesis.
class SoundService {
  bool enabled = true;

  Future<void> tap() async {}
  Future<void> pickUp() async {}
  Future<void> place() async {}
  Future<void> invalid() async {}
  Future<void> coin() async {}
  Future<void> win() async {}

  void dispose() {}
}
