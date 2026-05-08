/// Archbase Flutter — framework para apps Flutter empresariais.
///
/// Importa todos os módulos públicos da biblioteca.
library;

// Core
export 'src/core/archbase_bootstrap.dart';
export 'src/core/archbase_config.dart';
export 'src/core/archbase_env.dart';
export 'src/core/archbase_storage_keys.dart';
export 'src/core/exceptions/archbase_exception.dart';
export 'src/core/exceptions/api_exception.dart';
export 'src/core/exceptions/auth_exception.dart';
export 'src/core/state/archbase_service.dart';
export 'src/core/state/archbase_controller.dart';

// Models
export 'src/models/api_response.dart';
export 'src/models/paginated_response.dart';
export 'src/models/base_dto.dart';
export 'src/models/labeled_enum.dart';
export 'src/models/sync_operation.dart';

// Services
export 'src/services/api/archbase_api_client.dart';
export 'src/services/api/archbase_auth_interceptor.dart';
export 'src/services/api/archbase_logging_interceptor.dart';
export 'src/services/api/archbase_error_interceptor.dart';
export 'src/services/auth/archbase_auth_service.dart';
export 'src/services/auth/archbase_user.dart';
export 'src/services/auth/archbase_token_holder.dart';
export 'src/services/cache/archbase_cache_service.dart';
export 'src/services/connectivity/archbase_connectivity_service.dart';
export 'src/services/offline/archbase_offline_sync_queue.dart';
export 'src/services/offline/archbase_sync_status.dart';
export 'src/services/geolocation/archbase_geolocation_service.dart';
export 'src/services/push/archbase_push_notification_service.dart';
export 'src/services/media/archbase_image_service.dart';
export 'src/services/media/archbase_audio_recorder_service.dart';
export 'src/services/storage/archbase_storage_service.dart';

// Theme
export 'src/theme/archbase_colors.dart';
export 'src/theme/archbase_theme.dart';
export 'src/theme/archbase_theme_controller.dart';
export 'src/theme/archbase_theme_extensions.dart';
export 'src/theme/archbase_text_styles.dart';

// Utils
export 'src/utils/validators/archbase_validators.dart';
export 'src/utils/formatters/archbase_date_formatter.dart';
export 'src/utils/formatters/archbase_currency_formatter.dart';
export 'src/utils/formatters/archbase_phone_formatter.dart';
export 'src/utils/debouncer.dart';
export 'src/utils/jwt_utils.dart';
export 'src/utils/uuid_utils.dart';
export 'src/utils/responsive_utils.dart';
export 'src/utils/extensions/archbase_extensions.dart';

// Forms (sistema declarativo)
export 'src/forms/archbase_form.dart';
export 'src/forms/archbase_form_state.dart';
export 'src/forms/archbase_form_field.dart';
export 'src/forms/fields/archbase_form_text_field.dart';
export 'src/forms/fields/archbase_form_specialized_fields.dart';

// Widgets — feedback
export 'src/widgets/feedback/archbase_loading.dart';
export 'src/widgets/feedback/archbase_empty_state.dart';
export 'src/widgets/feedback/archbase_error_view.dart';
export 'src/widgets/feedback/archbase_shimmer.dart';
export 'src/widgets/feedback/archbase_sync_status_banner.dart';
// Widgets — forms
export 'src/widgets/forms/archbase_text_field.dart';
export 'src/widgets/forms/archbase_password_field.dart';
export 'src/widgets/forms/archbase_button.dart';
export 'src/widgets/forms/archbase_dropdown.dart';
export 'src/widgets/forms/archbase_search_field.dart';
export 'src/widgets/forms/archbase_numeric_stepper.dart';
export 'src/widgets/forms/archbase_country_picker.dart';
// Widgets — layout
export 'src/widgets/layout/archbase_app_bar.dart';
export 'src/widgets/layout/archbase_scaffold.dart';
export 'src/widgets/layout/archbase_section_header.dart';
export 'src/widgets/layout/archbase_card.dart';
export 'src/widgets/layout/archbase_draggable_home.dart';
export 'src/widgets/layout/archbase_floating_nav_bar.dart';
// Widgets — display
export 'src/widgets/display/archbase_text_avatar.dart';
export 'src/widgets/display/archbase_glass_container.dart';
export 'src/widgets/display/archbase_carousel.dart';
export 'src/widgets/display/archbase_badges_adv.dart';
// Widgets — structural
export 'src/widgets/structural/archbase_accordion.dart';
export 'src/widgets/structural/archbase_sticky_header.dart';
export 'src/widgets/structural/archbase_timeline.dart';
export 'src/widgets/structural/archbase_clippers.dart';
// Widgets — dialogs
export 'src/widgets/dialogs/archbase_confirm_dialog.dart';
export 'src/widgets/dialogs/archbase_alert_dialog.dart';
export 'src/widgets/dialogs/archbase_bottom_sheet.dart';
// Widgets — media
export 'src/widgets/media/archbase_audio_recorder_widget.dart';
export 'src/widgets/media/archbase_signature_pad.dart';
export 'src/widgets/media/archbase_photo_gallery.dart';
export 'src/widgets/media/archbase_barcode_scanner.dart';
export 'src/widgets/media/archbase_swipe_to_confirm.dart';

// Screens
export 'src/screens/login/archbase_login_screen.dart';
export 'src/screens/splash/archbase_splash_screen.dart';
export 'src/screens/crud/archbase_crud_list_screen.dart';
export 'src/screens/crud/archbase_crud_form_screen.dart';
export 'src/screens/crud/archbase_detail_screen.dart';
export 'src/screens/settings/archbase_settings_screen.dart';
export 'src/screens/intro/archbase_intro_screen.dart';
