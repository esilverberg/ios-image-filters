iphone-filters
=========

Uh, so everyone seems to want instagram-style filters for images on iPhone. The way to do this (I think) is to examine how people have implemented equivalent filters in Photoshop and code them in objective c. Unfortunately, the imaging libraries are all geared for gaming (meaning they're totally inscrutable and make you want to cry to do simple operations. Go on, try to understand the OpenGL sample code Apple ships for image processing. I dare you.) 

Inexplicably, there seem to be no photoshop-style interfaces for image processing on iOS. So, I made some. Badly. Please help me fix them. My lomo filter is OK, but could be a lot better. The basics seem to work.

How to integrate
======================
Copy and paste the ImageFilter.* classes into your project. It's implemented as categories on UIImage. 

How to use
======================
    #import "ImageFilter.h"
    UIImage *image = [UIImage imageNamed:@"landscape.jpg"];
    self.imageView.image = [image sharpen];
    // Or
    self.imageView.image = [image saturate:1.5];
    // Or
    self.imageView.image = [image lomo];

What is still broken
======================

- Gaussian blur is slow!
- More blend modes for layers
- Curves are catmull rom, not bicubic
- So much else...

Other options
=============
- Simple Image Processing: http://code.google.com/p/simple-iphone-image-processing/
- GLImageProcessing: http://developer.apple.com/library/ios/#samplecode/GLImageProcessing/Introduction/Intro.html

License
=======
MIT License, where applicable. I borrowed code from this project: http://sourceforge.net/projects/curve/files/ , which also indicates it is MIT-licensed. 
http://en.wikipedia.org/wiki/MIT_License