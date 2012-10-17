# UIImageView+NDVAnimatedGIFSupport #

Ever wanted to jam an image brimming with animated GIF goodness into a `UIImageView`?

Well you're in luck—with this `UIImageView` category, you can do precicely that!

------

Got an `NSURL`? No problem:

    NSURL *imageURL = [[NSBundle mainBundle] URLForResource:@"monkey-riding-a-goat" withExtension:@"gif"];
    UIImageView *imageView = [[[UIImageView alloc] ndv_initWithAnimatedGIFURL:imageURL] autorelease];

Perhaps you have an `NSData`? No sweat:

    NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
    UIImageView *imageView = [[[UIImageView alloc] ndv_initWithAnimatedGIFData:imageData] autorelease];

Now you too can keep the dream of the 90s alive with UIKit!
