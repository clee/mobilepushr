//
//  PushablePhotos
//
//  Created by Chris Lee on 2007-09-26.
//  Copyright (c) 2007. All rights reserved.
//

#import <UIKit/UIView.h>
#import <UIKit/UITable.h>
#import <UIKit/UIImageAndTextTableCell.h>

@class NSArray, NSString, PushablePhotosTable, RemovablePhotoCell;

@interface PushablePhotos : UIView
{
	PushablePhotosTable *_table;
}

- (NSArray *)photosToPush;

@end

@interface PushablePhotosTable : UITable
{
	NSMutableArray *_photos;
}

- (void)setPhotos: (NSArray *)photos;
- (void)removePhoto: (RemovablePhotoCell *)photoCell;
- (NSArray *)pushablePhotos;

@end

@interface RemovablePhotoCell : UIImageAndTextTableCell 
{
    PushablePhotosTable *_table;
    NSString *_path;
}

- (void)setTable: (PushablePhotosTable *)table;
- (void)setPath: (NSString *)path;
- (NSString *)path;

@end