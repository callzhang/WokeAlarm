//
//  ATDefaultMessageCenterTitleView.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/3/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATDefaultMessageCenterTitleView.h"

#import "ATBackend.h"
#import "ATConnect.h"
#import "ATConnect_Private.h"
#import "ATAppConfigurationUpdater.h"
#import "ATUtilities.h"

@implementation ATDefaultMessageCenterTitleView {

}
@synthesize title;
@synthesize imageView;

- (void)setup {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *titleString = [defaults objectForKey:ATAppConfigurationMessageCenterTitleKey];
	if (titleString == nil) {
		titleString = ATLocalizedString(@"Message Center", @"Message Center title text");
	}
	
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	//self.backgroundColor = [UIColor clearColor];
	if (![ATBackend sharedBackend].hideBranding) {
		UIImage *image = [ATBackend imageNamed:@"at_apptentive_icon_small"];
		imageView = [[UIImageView alloc] initWithImage:image];
		[self addSubview:imageView];
	}
	title = [[UILabel alloc] initWithFrame:CGRectZero];
	title.text = titleString;
	if ([title respondsToSelector:@selector(setMinimumScaleFactor:)]) {
		title.minimumScaleFactor = 0.5;
	} else {
#		pragma clang diagnostic push
#		pragma clang diagnostic ignored "-Wdeprecated-declarations"
		title.minimumFontSize = 10;
#		pragma clang diagnostic pop
	}
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
		title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
		title.textColor = [UIColor blackColor];
	} else {
		title.font = [UIFont boldSystemFontOfSize:20.];
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
			title.textColor = [UIColor whiteColor];
			title.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
		} else {
			title.textColor = [UIColor colorWithRed:113/255. green:120/255. blue:128/255. alpha:1];
			title.shadowColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.7];
			title.shadowOffset = CGSizeMake(0, 1);
		}
	}
	
	title.textAlignment = NSTextAlignmentLeft;
	title.lineBreakMode = NSLineBreakByTruncatingMiddle;
	title.backgroundColor = [UIColor clearColor];
	title.opaque = NO;
	title.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	if ([[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
		NSMutableDictionary *titleTextAttributes = [NSMutableDictionary dictionaryWithDictionary:[[UINavigationBar appearance] titleTextAttributes]];
		titleTextAttributes[NSBackgroundColorAttributeName] = [UIColor clearColor];
		
		if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
			title.attributedText = [[[NSAttributedString alloc] initWithString:title.text attributes:titleTextAttributes] autorelease];
		} else {
#			pragma clang diagnostic push
#			pragma clang diagnostic ignored "-Wdeprecated-declarations"
			UIColor *textColor = (UIColor *)titleTextAttributes[UITextAttributeTextColor];
			UIColor *shadowColor = (UIColor *)titleTextAttributes[UITextAttributeTextShadowColor];
			UIFont *font = (UIFont *)titleTextAttributes[UITextAttributeFont];
			NSValue *shadowOffset = (NSValue *)titleTextAttributes[UITextAttributeTextShadowOffset];
			
			if (textColor) {
				title.textColor = textColor;
			}
			if (shadowColor) {
				title.shadowColor = shadowColor;
			}
			if (font) {
				title.font = [UIFont fontWithName:font.fontName size:20];
			}
			if (shadowOffset) {
				UIOffset offset = [shadowOffset UIOffsetValue];
				title.shadowOffset = CGSizeMake(offset.horizontal, offset.vertical);
			}
#			pragma clang diagnostic pop
		}
	}
	
	[self addSubview:title];
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self setup];
	}
	return self;
}

- (void)awakeFromNib {
	[self setup];
}

- (void)dealloc {
	[title release], title = nil;
	[imageView release], imageView = nil;
	[super dealloc];
}

- (void)layoutSubviews {
	CGFloat padding = 4;
	CGRect imageRect = self.imageView ? self.imageView.frame : CGRectZero;
	
	[title sizeToFit];
	CGFloat titleWidth = title.bounds.size.width;
	CGFloat imageSpace = imageRect.size.width + padding;
	if (titleWidth > (self.bounds.size.width - imageSpace)) {
		titleWidth -= imageSpace;
	}
	
	CGFloat titleOriginX = floor(self.bounds.size.width*0.5 - titleWidth*0.5 + imageRect.size.width*0.5);
	imageRect.origin.x = titleOriginX - imageRect.size.width - padding;
	imageRect.origin.y = floor(self.bounds.size.height*0.5 - imageRect.size.height*0.5);
	if (self.imageView) {
		self.imageView.frame = imageRect;
	}
	
	CGRect titleRect = self.title.frame;
	titleRect.origin.x = titleOriginX;
	titleRect.size.width = titleWidth;
	titleRect.size.height = self.bounds.size.height;
	self.title.frame = titleRect;
}
@end
