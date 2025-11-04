import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ResponsiveHelper {
  // Screen size breakpoints - Updated for better web experience
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1600;

  // Check device type
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktopBreakpoint;
  }

  static bool isWeb() {
    return kIsWeb;
  }

  // Get current device type
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= largeDesktopBreakpoint) return DeviceType.largeDesktop;
    if (width >= tabletBreakpoint) return DeviceType.desktop;
    if (width >= mobileBreakpoint) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  // Get screen width percentage
  static double getScreenWidthPercentage(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * (percentage / 100);
  }

  // Get screen height percentage
  static double getScreenHeightPercentage(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * (percentage / 100);
  }

  // Enhanced responsive values with large desktop support
  static T responsive<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    if (isLargeDesktop(context) && largeDesktop != null) return largeDesktop;
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  // Responsive values with fallback for web/desktop optimization
  static T responsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }

  // Responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    return EdgeInsets.all(
      responsive(context: context, mobile: 16.0, tablet: 20.0, desktop: 24.0),
    );
  }

  // Responsive margin
  static EdgeInsets responsiveMargin(BuildContext context) {
    return EdgeInsets.all(
      responsive(context: context, mobile: 8.0, tablet: 12.0, desktop: 16.0),
    );
  }

  // Responsive font sizes
  static double responsiveFontSize(
    BuildContext context, {
    required double baseFontSize,
    double? mobileScale,
    double? tabletScale,
    double? desktopScale,
  }) {
    final scale = responsive<double>(
      context: context,
      mobile: mobileScale ?? 0.9,
      tablet: tabletScale ?? 1.0,
      desktop: desktopScale ?? 1.1,
    );
    return baseFontSize * scale;
  }

  // Grid view configurations
  static GridConfiguration getGridConfig(
    BuildContext context, {
    int? mobileColumns,
    int? tabletColumns,
    int? desktopColumns,
    double? mobileAspectRatio,
    double? tabletAspectRatio,
    double? desktopAspectRatio,
  }) {
    return GridConfiguration(
      crossAxisCount: responsive(
        context: context,
        mobile: mobileColumns ?? 1,
        tablet: tabletColumns ?? 2,
        desktop: desktopColumns ?? 3,
      ),
      childAspectRatio: responsive(
        context: context,
        mobile: mobileAspectRatio ?? 2.5,
        tablet: tabletAspectRatio ?? 1.5,
        desktop: desktopAspectRatio ?? 1.2,
      ),
      spacing: responsive(
        context: context,
        mobile: 8.0,
        tablet: 12.0,
        desktop: 16.0,
      ),
    );
  }

  // Card configurations
  static CardConfiguration getCardConfig(BuildContext context) {
    return CardConfiguration(
      padding: EdgeInsets.all(
        responsive(context: context, mobile: 12.0, tablet: 16.0, desktop: 20.0),
      ),
      margin: EdgeInsets.all(
        responsive(context: context, mobile: 4.0, tablet: 6.0, desktop: 8.0),
      ),
      borderRadius: responsive(
        context: context,
        mobile: 12.0,
        tablet: 16.0,
        desktop: 20.0,
      ),
    );
  }

  // Icon sizes
  static double getIconSize(BuildContext context, {double baseSize = 24.0}) {
    return responsive(
      context: context,
      mobile: baseSize * 0.8,
      tablet: baseSize,
      desktop: baseSize * 1.2,
    );
  }

  // Avatar sizes
  static double getAvatarRadius(
    BuildContext context, {
    double baseRadius = 30.0,
  }) {
    return responsive(
      context: context,
      mobile: baseRadius * 0.8,
      tablet: baseRadius,
      desktop: baseRadius * 1.1,
    );
  }
}

class GridConfiguration {
  final int crossAxisCount;
  final double childAspectRatio;
  final double spacing;

  GridConfiguration({
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.spacing,
  });
}

class CardConfiguration {
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double borderRadius;

  CardConfiguration({
    required this.padding,
    required this.margin,
    required this.borderRadius,
  });
}

// Responsive GridView widget
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double? mobileAspectRatio;
  final double? tabletAspectRatio;
  final double? desktopAspectRatio;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.mobileAspectRatio,
    this.tabletAspectRatio,
    this.desktopAspectRatio,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    final config = ResponsiveHelper.getGridConfig(
      context,
      mobileColumns: mobileColumns,
      tabletColumns: tabletColumns,
      desktopColumns: desktopColumns,
      mobileAspectRatio: mobileAspectRatio,
      tabletAspectRatio: tabletAspectRatio,
      desktopAspectRatio: desktopAspectRatio,
    );

    return GridView.count(
      shrinkWrap: shrinkWrap,
      physics: physics,
      crossAxisCount: config.crossAxisCount,
      mainAxisSpacing: config.spacing,
      crossAxisSpacing: config.spacing,
      childAspectRatio: config.childAspectRatio,
      children: children,
    );
  }
}

// Responsive text widget
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final double? mobileScale;
  final double? tabletScale;
  final double? desktopScale;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const ResponsiveText(
    this.text, {
    super.key,
    this.baseStyle,
    this.mobileScale,
    this.tabletScale,
    this.desktopScale,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final style = baseStyle ?? Theme.of(context).textTheme.bodyMedium!;
    final fontSize = style.fontSize ?? 14.0;

    final responsiveFontSize = ResponsiveHelper.responsiveFontSize(
      context,
      baseFontSize: fontSize,
      mobileScale: mobileScale,
      tabletScale: tabletScale,
      desktopScale: desktopScale,
    );

    return Text(
      text,
      style: style.copyWith(fontSize: responsiveFontSize),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}

// Device type enum
enum DeviceType { mobile, tablet, desktop, largeDesktop }
