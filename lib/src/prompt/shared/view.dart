/// View calculations.
library;

typedef ViewInfo = ({
  int index,
  int viewLimit,
  int endOverflow,
  int viewIndex,
  int viewStart,
  int viewEnd,
  int topDisparity,
  int bottomDisparity,
  int topDistance,
  int bottomDistance,
});

/// Computes the appropriate values for a view with the given [length] and actual [index].
ViewInfo computeViewInfo(
  int length, {
  required int index,
  int topDisparity = 1,
  int bottomDisparity = 1,
  int topDistance = 2,
  int bottomDistance = 2,
}) {
  int viewLimit = topDistance + bottomDistance + 1;
  int endOverflow = (index - topDisparity + viewLimit - length).clamp(0, bottomDistance);
  int viewStart =  (index - topDistance - endOverflow).clamp(0, length - viewLimit);
  int viewEnd = viewStart + viewLimit;
  int viewIndex = index - viewStart;

  return (
    index: index,
    viewLimit: viewLimit,
    endOverflow: endOverflow,
    viewIndex: viewIndex,
    viewStart: viewStart,
    viewEnd: viewEnd,
    topDisparity: topDisparity,
    bottomDisparity: bottomDisparity,
    topDistance: topDistance,
    bottomDistance: bottomDistance,
  );
}
