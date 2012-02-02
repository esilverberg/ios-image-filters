ios-image-filters
======================

These days everyone seems to want instagram-style filters for images on iPhone. The way to do this (I think) is to examine how people have implemented equivalent filters in Photoshop and code them in objective c. Unfortunately, the imaging libraries are all geared for gaming. For non-game developers who just want simple image processing, this is overkill.

It's like photoshop for the UIImage class!
======================
I've worked hard to mimic the photoshop color adjustment menus. Turns out these are clutch in pretty much all the best image filters you can name right now (lomo, polaroid). For example, if you want to manipulate levels, here's your method, built straight onto the UIImage class:

    - (UIImage*) levels:(NSInteger)black mid:(NSInteger)mid white:(NSInteger)white

An API just like that cool menu in Photoshop!

Want to do a curves adjustment to mimic a filter you saw on a blog? Just do this:

    NSArray *redPoints = [NSArray arrayWithObjects:
            [NSValue valueWithCGPoint:CGPointMake(0, 0)],
            [NSValue valueWithCGPoint:CGPointMake(93, 76)],
            [NSValue valueWithCGPoint:CGPointMake(232, 226)],
            [NSValue valueWithCGPoint:CGPointMake(255, 255)],
            nil];
    NSArray *bluePoints = [NSArray arrayWithObjects:
             [NSValue valueWithCGPoint:CGPointMake(0, 0)],
             [NSValue valueWithCGPoint:CGPointMake(57, 59)],
             [NSValue valueWithCGPoint:CGPointMake(220, 202)],
             [NSValue valueWithCGPoint:CGPointMake(255, 255)],
             nil];
    UIImage *image = [[[UIImage imageNamed:@"landscape.jpg" applyCurve:redPoints toChannel:CurveChannelRed] 
     applyCurve:bluePoints toChannel:CurveChannelBlue];

The problem with my curves implementation is that I didn't use the same kind of curve algorithm as Photoshop uses. Mainly, because I don't know how, and other than the name of the curve (bicubic) all the posts and documentation I simply don't understand or cannot figure out how to port to iOS. But, the curves I use (catmull-rom) seem close enough.

How to integrate
======================
Copy and paste the ImageFilter.* and Curves/* classes into your project. It's implemented a Category on UIImage.

How to use
======================
    #import "ImageFilter.h"
    UIImage *image = [UIImage imageNamed:@"landscape.jpg"];
    self.imageView.image = [image sharpen];
    // Or
    self.imageView.image = [image saturate:1.5];
    // Or
    self.imageView.image = [image lomo];

What it looks like
======================
![Screen shot 1](/esilverberg/ios-image-filters/raw/master/docs/ss1.png)
![Screen shot 2](/esilverberg/ios-image-filters/raw/master/docs/ss2.png)


What is still broken
======================

- Gaussian blur is slow!
- More blend modes for layers
- Curves are catmull rom, not bicubic
- So much else...

Other options
=============
I tried, but mostly failed, to understand these libraries. Simple Image Processing is too simple, and uses a CPP class to accomplish its effects, as does CImg. I find the CPP syntax ghoulish, to say the least. I stared at the GLImageProcessing code for hours, and still don't understand what's going on. Guess I should have taken CS244a...

UPDATE: Core image filters in iOS5 are probably what you want to use going forward, though they are not backwards-compatible with iOS4 or earlier. 

- Core Image Filters: http://developer.apple.com/library/mac/#documentation/graphicsimaging/reference/CoreImageFilterReference/Reference/reference.html
- Simple Image Processing: http://code.google.com/p/simple-iphone-image-processing/
- GLImageProcessing: http://developer.apple.com/library/ios/#samplecode/GLImageProcessing/Introduction/Intro.html
- CImg: http://cimg.sourceforge.net/reference/group__cimg__tutorial.html 

License
=======
MIT License, where applicable. I borrowed code from this project: http://sourceforge.net/projects/curve/files/ , which also indicates it is MIT-licensed. 
http://en.wikipedia.org/wiki/MIT_License

There is also now code adapted from ImageMagick, whose license may be found at: http://www.imagemagick.org/script/license.php