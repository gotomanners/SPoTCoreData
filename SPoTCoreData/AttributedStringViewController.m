//
//  AttributedStringViewController.m
//  SPoT
//
//  Created by Manners Oshafi on 26/10/2013.
//  Copyright (c) 2013 Gotomanners. All rights reserved.
//

#import "AttributedStringViewController.h"

@interface AttributedStringViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation AttributedStringViewController

- (void)setText:(NSAttributedString *)text {
    _text = text;
    self.textView.attributedText = self.text;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textView.attributedText = self.text;
}
@end
