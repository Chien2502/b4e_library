/// Tập trung các key và TTL của cache SQLite
class CacheKeys {
  CacheKeys._();

  // ── Home screen ─────────────────────────────────────────────────
  static const String homePopular         = 'home_popular';
  static const String homeLatest          = 'home_latest';
  static const String homeRecommendations = 'home_recommendations';

  // ── User ────────────────────────────────────────────────────────
  static const String userProfile = 'user_profile';

  // ── Static pages (content tĩnh, ít thay đổi) ───────────────────
  static const String pageGuide   = 'page_guide';
  static const String pagePolicy  = 'page_policy';
  static const String pageSupport = 'page_support';
  static const String pageAbout   = 'page_about';

  // ── TTL (seconds) ───────────────────────────────────────────────
  /// 30 phút — gợi ý cá nhân (thay đổi thường xuyên)
  static const int ttlShort = 1800;

  /// 1 giờ — sách phổ biến / mới nhất
  static const int ttlMedium = 3600;

  /// 1 ngày — profile user
  static const int ttlLong = 86400;

  /// 30 ngày — nội dung tĩnh (guide/policy/support/about)
  static const int ttlStatic = 2592000;
}
