/// Flutter widget that displays a sliding image gallery.
library sliding_image_gallery;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A widget that displays a gallery of images.
class ImageGallery extends StatefulWidget {
  /// List of a url of images to be displayed.
  final List<String> images;

  /// The number of images to be displayed at a time
  final int galleryLength;

  /// Duration of the sliding animation in milliseconds
  final int animationDuration;

  /// Creates a new [ImageGallery] widget.
  /// [images] is a list of urls of images to be displayed.
  /// [galleryLength] is the number of images to be displayed at a time.
  /// [animationDuration] is the duration of the sliding animation in milliseconds.
  ///
  /// The [images] argument must not be null.
  const ImageGallery({
    Key? key,
    required this.images,
    this.galleryLength = 4,
    this.animationDuration = 300,
  }) : super(key: key);

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery>
    with SingleTickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController controller;

  late List<String> galleryImages;
  // late Map<int, String> imgMap;

  int _currIndex = 0;

  double scale = 4 / 5;

  double screenWidth = 0;
  bool firstBuild = true;

  bool _isRight = true;

  @override
  void initState() {
    super.initState();
    if (widget.images.isEmpty || widget.images.length == 1) {
      return;
    }
    galleryImages = widget.images
        .sublist(0, math.min(widget.galleryLength, widget.images.length));

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animationDuration),
      value: 1,
    );

    animation = Tween<double>(begin: 0, end: 1).animate(controller)
      ..addStatusListener((status) {
        if ((status == AnimationStatus.completed && !_isRight) ||
            (status == AnimationStatus.dismissed && _isRight)) {
          _swapUptoInd(_isRight);
        }
      })
      ..addListener(() {
        setState(() {
          // The state that has changed here is the animation object’s value.
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    if (firstBuild) {
      screenWidth = MediaQuery.of(context).size.width;
      firstBuild = false;
    }

    if (widget.images.length == 0) {
      return Container();
    }

    if (widget.images.length == 1) {
      String img = widget.images[0];
      return Material(
        type: MaterialType.transparency,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          padding: EdgeInsets.all(10),
          child: Ink(
            // width: 100,
            width: screenWidth * scale,
            // height: 100,
            height: screenWidth * scale,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                fit: BoxFit.cover,
                image: CachedNetworkImageProvider(
                  img,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: screenWidth,
      height: (screenWidth + 40) * scale,
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          // Swiping in right direction.
          if (details.primaryVelocity! > 0) {
            _startAnimation(true);
          }

          // Swiping in left direction.
          if (details.primaryVelocity! < 0) {
            _startAnimation(false);
          }
        },
        // onTap: () {
        //   _swapUptoInd(true);
        // },
        child: Stack(
          alignment: AlignmentDirectional.centerStart,
          children: galleryImages
              .asMap()
              .entries
              .map<Widget>((e) {
                bool useAnim =
                    !((controller.status == AnimationStatus.completed &&
                            !_isRight) ||
                        (controller.status == AnimationStatus.dismissed &&
                            _isRight));

                double firstVisibility = (!_isRight
                        ? e.key == 0 && useAnim
                            ? animation.value
                            : useAnim
                                ? e.key - animation.value
                                : e.key
                        : useAnim
                            ? e.key + (1 - animation.value)
                            : e.key)
                    .toDouble();

                double normalAnim = (!_isRight
                        ? useAnim
                            ? e.key - animation.value
                            : e.key
                        : useAnim
                            ? e.key + (1 - animation.value)
                            : e.key)
                    .toDouble();

                double imgWidth = screenWidth * scale - firstVisibility * 20;
                double left = normalAnim * 30;
                double opacity = 1 - firstVisibility * 0.2;
                if (opacity > 1) opacity = 1;
                if (opacity < 0) opacity = 0;

                return Positioned(
                  // top: 0,
                  left: left,
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () => _startAnimation(false),
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10)),
                        child: Ink(
                          width: imgWidth,
                          height: imgWidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: CachedNetworkImageProvider(
                                e.value,
                              ),
                              colorFilter: ColorFilter.mode(
                                Colors.white.withOpacity(opacity),
                                BlendMode.dstATop,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              })
              .toList()
              .reversed
              .toList(),
        ),
      ),
    );
  }

  void _startAnimation(bool right) {
    if (controller.value != 1 && controller.value != 0) {
      _swapUptoInd(right);
    }
    if (!right) {
      controller.forward(from: 0);
    } else {
      controller.reverse(from: 1);
    }
    _isRight = right;
  }

  void _swapUptoInd(bool right) {
    int index = right ? _currIndex - 1 : _currIndex + 1;
    if (index == -1) index = widget.images.length - 1;
    if (index == widget.images.length) index = 0;
    List<String> newGalleryImages = [
      ...widget.images.sublist(index),
      ...widget.images.sublist(0, index)
    ].sublist(0, math.min(widget.galleryLength, widget.images.length));
    setState(() {
      galleryImages = newGalleryImages;
      _currIndex = index;
    });
  }
}
