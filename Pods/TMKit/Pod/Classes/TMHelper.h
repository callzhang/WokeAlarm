//
//  TMHelper.h
//  Pods
//
//  Created by Zitao Xiong on 5/12/15.
//
//

#import <Foundation/Foundation.h>

#if !defined(TM_INLINE)
#  if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L
#    define TM_INLINE static inline
#  elif defined(__cplusplus)
#    define TM_INLINE static inline
#  elif defined(__GNUC__)
#    define TM_INLINE static __inline__
#  else
#    define TM_INLINE static
#  endif
#endif

/*
 * Helpers for completions which call the block only if non-nil
 *
 */
#define TM_BLOCK_EXEC(block, ...) if (block) { block(__VA_ARGS__); };

#define TM_DISPATCH_EXEC(queue, block, ...) if (block) { dispatch_async(queue, ^{ block(__VA_ARGS__); } ); }

#define STRINGIFY2( x) #x
#define STRINGIFY(x) STRINGIFY2(x)

CGFloat TMExpectedLabelHeight(UILabel *label);
void TMAdjustHeightForLabel(UILabel *label);

id TMDynamicCast_(id x, Class objClass);
#define TMDynamicCast(x, c) ((c *) TMDynamicCast_(x, [c class]))

UIImage *TMImageWithColor(UIColor *color);

UIColor *TMRGB(uint32_t x);
UIColor *TMRGBA(uint32_t x, CGFloat alpha);

TM_INLINE CGFloat
TMCGFloatNearlyEqualToFloat(CGFloat f1, CGFloat f2) {
    const CGFloat TMCGFloatEpsilon = 0.01; // 0.01 should be safe enough when dealing with screen point and pixel values
    return (ABS(f1 - f2) <= TMCGFloatEpsilon);
}