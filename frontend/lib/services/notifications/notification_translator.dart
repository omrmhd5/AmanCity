import 'package:flutter/foundation.dart';

class NotificationTranslator {
  /// Translates notification title and body based on the alert type and user's locale.
  static MapEntry<String, String> translate({
    required String type,
    required Map<String, dynamic> data,
    required String lang,
    String? fallbackTitle,
    String? fallbackBody,
  }) {
    final isAr = lang == 'ar';

    switch (type) {
      case 'sos_alert':
        final name = data['triggerUserName'] as String? ?? '';
        final title = isAr
            ? '🆘 ${name.isNotEmpty ? name : "جهة اتصال"} في خطر!'
            : '🆘 ${name.isNotEmpty ? name : "a contact"} is in danger!';
        final body = isAr
            ? 'انقر لعرض موقعهم المباشر والاتصال لطلب المساعدة.'
            : 'Tap to view their live location and call for help.';
        return MapEntry(title, body);

      case 'sos_ended':
        final name = data['triggerUserName'] as String? ?? '';
        final title = isAr
            ? '✅ ${name.isNotEmpty ? name : "جهة اتصال"} الآن بأمان'
            : '✅ ${name.isNotEmpty ? name : "A contact"} is now safe';
        final body = isAr
            ? 'لقد قاموا بإلغاء تنبيه نداء الاستغاثة الخاص بهم.'
            : 'They have cancelled their SOS alert.';
        return MapEntry(title, body);

      case 'contact_request':
      case 'contactRequest':
        final name = data['fromUserName'] as String? ?? '';
        final title = isAr
            ? '👤 طلب إضافة جهة اتصال استغاثة من ${name.isNotEmpty ? name : "شخص ما"}'
            : '👤 SOS Contact request from ${name.isNotEmpty ? name : "someone"}';
        final body = isAr
            ? 'افتح التطبيق للقبول أو الرفض.'
            : 'Open the app to accept or decline.';
        return MapEntry(title, body);

      case 'contact_accepted':
      case 'contactAccepted':
        final name = data['fromUserName'] as String? ?? '';
        final title = isAr
            ? '✅ قبل ${name.isNotEmpty ? name : "شخص ما"} طلب اتصال الاستغاثة الخاص بك'
            : '✅ ${name.isNotEmpty ? name : "Someone"} accepted your SOS contact request';
        final body = isAr
            ? 'يمكنكم الآن إرسال تنبيهات الاستغاثة لبعضكم البعض.'
            : 'You can now send SOS alerts to each other.';
        return MapEntry(title, body);

      case 'nearbyIncident':
        final incidentTitle = data['incidentTitle'] as String? ?? fallbackTitle ?? data['title'] as String? ?? 'Incident';
        final incidentType = data['incidentType'] as String? ?? '';
        
        // Translate incident type
        final translatedType = isAr ? _translateIncidentType(incidentType) : incidentType;
        final title = isAr
            ? '$incidentTitle · تنبيه $translatedType ⚠️'
            : '$incidentTitle · $incidentType Alert ⚠️';

        // Translate location text if it's "your area"
        final locationText = data['locationText'] as String? ?? '';
        final translatedLocation = (locationText == 'your area' || locationText.isEmpty)
            ? (isAr ? 'منطقتك' : 'your area')
            : locationText;
        
        final body = isAr
            ? 'تم الإبلاغ بالقرب من في نطاق 2 كم و $translatedLocation. ابقَ حذراً.'
            : 'Reported near within 2km and $translatedLocation. Stay alert.';
        return MapEntry(title, body);

      case 'system':
        final title = fallbackTitle ?? (data['title'] as String?) ?? 'Alert';
        final body = fallbackBody ?? (data['body'] as String?) ?? '';
        if (title.contains('Test Alert')) {
          return MapEntry(
            isAr ? 'تنبيه تجريبي · تنبيه تجريبي ⚠️' : 'Test Alert · Test Alert ⚠️',
            isAr
                ? 'تم الإبلاغ بالقرب من في نطاق 2 كم وموقع تجريبي. ابقَ حذراً.'
                : 'Reported near within 2km and test location. Stay alert.',
          );
        }
        return MapEntry(title, body);

      default:
        // Fallback to whatever is already in the data/notification payload
        final title = fallbackTitle ?? (data['title'] as String?) ?? 'Alert';
        final body = fallbackBody ?? (data['body'] as String?) ?? '';
        return MapEntry(title, body);
    }
  }

  static String _translateIncidentType(String type) {
    switch (type) {
      case 'Fire': return 'حريق';
      case 'Accident': return 'حادث';
      case 'Flood': return 'فيضان';
      case 'Public Issue': return 'مشكلة عامة';
      case 'Road Damage': return 'أضرار بالطريق';
      case 'Damaged Building': return 'مبنى متضرر';
      case 'Firearm': return 'سلاح ناري';
      case 'Cold Weapon': return 'سلاح أبيض';
      case 'Arrest': return 'اعتقال';
      case 'Arson': return 'حريق متعمد';
      case 'Assault': return 'اعتداء';
      case 'Burglary': return 'سطو';
      case 'Explosion': return 'انفجار';
      case 'Fighting': return 'شجار';
      case 'Robbery': return 'سرقة بالإكراه';
      case 'Shooting': return 'إطلاق نار';
      case 'Shoplifting': return 'سرقة متاجر';
      case 'Stealing': return 'سرقة';
      case 'Vandalism': return 'تخريب';
      case 'Others': return 'أخرى';
      default: return type;
    }
  }
}
