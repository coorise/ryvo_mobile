bool isRealStorageKey(String? key) {
  if (key == null || key.trim().isEmpty) return false;
  if (key.startsWith('pending/')) return false;
  if (key.startsWith('seed/')) return false;
  return true;
}
