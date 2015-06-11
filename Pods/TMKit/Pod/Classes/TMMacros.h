//
//  TMMacros.h
//  Pods
//
//  Created by Zitao Xiong on 5/5/15.
//
//

#ifndef Pods_TMMacros_h
#define Pods_TMMacros_h

#ifndef TMP_REQUIRES_SUPER
#if __has_attribute(objc_requires_super)
#define TMP_REQUIRES_SUPER __attribute__((objc_requires_super))
#else
#define TMP_REQUIRES_SUPER
#endif
#endif

#if defined(__cplusplus)
#define TM_EXTERN extern "C" __attribute__((visibility("default")))
#else
#define TM_EXTERN extern __attribute__((visibility("default")))
#endif

#endif
