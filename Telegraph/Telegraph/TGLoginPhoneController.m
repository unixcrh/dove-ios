#import "TGLoginPhoneController.h"

#import "TGImageUtils.h"

#import "TGToolbarButton.h"
#import "TGPhoneUtils.h"

#import "TGNavigationBar.h"
#import "TGNavigationController.h"

#import "TGAppDelegate.h"

#import "TGHacks.h"
#import "TGStringUtils.h"
#import "TGFont.h"

#import "TGInterfaceAssets.h"

#import "TGLoginCodeController.h"
#import "TGLoginCountriesController.h"

#import "SGraphObjectNode.h"

#import "TGLoginProfileController.h"

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#import "TGProgressWindow.h"

#import "TGHighlightableButton.h"
#import "TGBackspaceTextField.h"

#import "TGActivityIndicatorView.h"

#import "TGSendCodeRequestBuilder.h"

#import "TGAlertView.h"

#import "TGObserverProxy.h"

#import "TGPhoneUtils.h"
#import "TGWebViewController.h"

@interface TGLoginPhoneController () <UITextFieldDelegate>
{
    UIView *_grayBackground;
    UIView *_separatorView;
    UILabel *_titleLabel;
    UILabel *_noticeLabel;
    UILabel *_termsLabel;
    UIButton *_termsButton;
    UIImageView *_inputBackgroundView;
    
    TGObserverProxy *_keyValueStoreChangeProxy;
    bool _editedText;
}

@property (nonatomic, strong) NSString *presetPhoneCountry;
@property (nonatomic, strong) NSString *presetPhoneNumber;

@property (nonatomic, strong) TGProgressWindow *progressWindow;

@property (nonatomic, strong) UIButton *countryButton;

@property (nonatomic, strong) UITextField *countryCodeField;
@property (nonatomic, strong) TGBackspaceTextField *phoneField;

@property (nonatomic) CGRect basePhoneFieldFrame;
@property (nonatomic) CGRect baseInputBackgroundViewFrame;
@property (nonatomic) CGRect baseCountryCodeFieldFrame;

@property (nonatomic) bool inProgress;
@property (nonatomic) int currentActionIndex;

@property (nonatomic, strong) NSString *phoneNumber;

@property (nonatomic, strong) UIAlertView *currentAlert;

@property (nonatomic, strong) UIView *shadeView;

@end

@implementation TGLoginPhoneController

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        
        [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Next") style:UIBarButtonItemStyleDone target:self action:@selector(nextButtonPressed)]];
    }
    return self;
}

- (void)dealloc
{
    [self doUnloadView];
    
    _currentAlert.delegate = nil;
    
    [_actionHandle reset];
    [ActionStageInstance() removeWatcher:self];
}

- (void)setPhoneNumber:(NSString *)phoneNumber
{
    if ([phoneNumber rangeOfString:@"|"].location == NSNotFound)
        return;
    
    _presetPhoneCountry = [phoneNumber substringToIndex:[phoneNumber rangeOfString:@"|"].location];
    _presetPhoneNumber = [phoneNumber substringFromIndex:[phoneNumber rangeOfString:@"|"].location + 1];
    
    if (self.isViewLoaded)
        [self _applyPresetNumber];
}

- (void)_applyPresetNumber
{
    if (_presetPhoneNumber != nil && _presetPhoneCountry != nil)
    {
        _countryCodeField.text = _presetPhoneCountry;
        _phoneField.text = _presetPhoneNumber;
        
        _presetPhoneCountry = nil;
        _presetPhoneNumber = nil;
        
        [self updatePhoneTextForCountryFieldText:_countryCodeField.text];
        [self updateCountry];
    }
}

- (void)viewDidLayoutSubviews
{
    if (!_phoneField.isFirstResponder && !_countryCodeField.isFirstResponder)
        [_phoneField becomeFirstResponder];
    
    [super viewDidLayoutSubviews];
}

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGSize screenSize = [self referenceViewSizeForOrientation:UIInterfaceOrientationPortrait];
    
    _grayBackground = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, screenSize.width, [TGViewController isWidescreen] ? 131.0f : 64.0f)];
    //    _grayBackground.backgroundColor = UIColorRGB(0xf2f2f2);
    //qi.zhang modify
    _grayBackground.backgroundColor = UIColorRGB(0x007de3);
    [self.view addSubview:_grayBackground];
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textColor = [UIColor whiteColor]; //qi.zhang modify
    _titleLabel.font = TGIsPad() ? TGUltralightSystemFontOfSize(48.0f) : ([TGViewController isWidescreen] ? TGLightSystemFontOfSize(24.0f):TGLightSystemFontOfSize(30.0f));
    _titleLabel.text = TGLocalized(@"Login.PhoneTitle");
    [_titleLabel sizeToFit];
    _titleLabel.frame = CGRectMake(CGFloor((screenSize.width - _titleLabel.frame.size.width) / 2), [TGViewController isWidescreen] ? 71.0f : 22.0f, _titleLabel.frame.size.width, _titleLabel.frame.size.height);
    [self.view addSubview:_titleLabel];
    
    _noticeLabel = [[UILabel alloc] init];
    _noticeLabel.font = TGSystemFontOfSize(15.0f);
    _noticeLabel.textColor = UIColorRGB(0x999999);
    _noticeLabel.text = TGLocalized(@"Login.PhoneAndCountryHelp");
    _noticeLabel.backgroundColor = [UIColor clearColor];
    _noticeLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _noticeLabel.textAlignment = NSTextAlignmentCenter;
    _noticeLabel.contentMode = UIViewContentModeCenter;
    _noticeLabel.numberOfLines = 0;
    CGSize noticeSize = [_noticeLabel sizeThatFits:CGSizeMake(278.0f, CGFLOAT_MAX)];
    CGFloat noticeY = [TGViewController isWidescreen] ? (screenSize.height>568.0f ? 274.0f:244.0f) : 188.0f;
    _noticeLabel.frame = CGRectMake(CGFloor((screenSize.width - noticeSize.width) / 2.0f), noticeY, noticeSize.width, noticeSize.height);
    [self.view addSubview:_noticeLabel];
    
    _termsLabel = [[UILabel alloc] init];
    _termsLabel.font = TGSystemFontOfSize(15.0f);
    _termsLabel.textColor = UIColorRGB(0x999999);
    _termsLabel.text = TGLocalized(@"Login.UserProtocolInfo");
    _termsLabel.backgroundColor = [UIColor clearColor];
    _termsLabel.textAlignment = NSTextAlignmentCenter;
    [_termsLabel sizeToFit];
    _termsLabel.center = CGPointMake(self.view.bounds.size.width/2, _noticeLabel.frame.origin.y+_noticeLabel.frame.size.height+10+_termsLabel.frame.size.height/2);
    [self.view addSubview:_termsLabel];
    
    _termsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _termsButton.titleLabel.font = TGSystemFontOfSize(15.0f);
    _termsButton.backgroundColor = [UIColor clearColor];
    [_termsButton setTitle:TGLocalized(@"Login.UserProtocol") forState:UIControlStateNormal];
    [_termsButton sizeToFit];
    _termsButton.center = CGPointMake(self.view.bounds.size.width/2, _termsLabel.frame.origin.y+_termsLabel.frame.size.height-5+_termsButton.frame.size.height/2);
    [_termsButton addTarget:self action:@selector(termButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_termsButton];
    
    UIImage *rawCountryImage = [UIImage imageNamed:@"ModernAuthCountryButton.png"];
    UIImage *rawCountryImageHighlighted = [UIImage imageNamed:@"ModernAuthCountryButtonHighlighted.png"];
    
    _countryButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, rawCountryImage.size.height)];
    _countryButton.exclusiveTouch = true;
    [_countryButton setBackgroundImage:[rawCountryImage stretchableImageWithLeftCapWidth:(int)(rawCountryImage.size.width / 2.0f) topCapHeight:0] forState:UIControlStateNormal];
    [_countryButton setBackgroundImage:[rawCountryImageHighlighted stretchableImageWithLeftCapWidth:(int)(rawCountryImageHighlighted.size.width / 2.0f) topCapHeight:0] forState:UIControlStateHighlighted];
    _countryButton.titleLabel.font = TGSystemFontOfSize(20.0f);
    _countryButton.titleLabel.textAlignment = NSTextAlignmentLeft;
    _countryButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [_countryButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _countryButton.titleEdgeInsets = UIEdgeInsetsMake(0, 14, 9, 14);
    [_countryButton addTarget:self action:@selector(countryButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    _countryButton.frame = CGRectMake(0.0f, [TGViewController isWidescreen] ? 131.0f : 64.0f, screenSize.width, rawCountryImage.size.height);
    [self.view addSubview:_countryButton];
    
    UIImage *rawInputImage = [UIImage imageNamed:@"ModernAuthPhoneBackground.png"];
    _inputBackgroundView = [[UIImageView alloc] initWithImage:[rawInputImage stretchableImageWithLeftCapWidth:(int)(rawInputImage.size.width / 2) topCapHeight:(int)(rawInputImage.size.height / 2)]];
    _inputBackgroundView.frame = CGRectMake(0.0f, _countryButton.frame.origin.y + 57.0f, screenSize.width, rawInputImage.size.height + TGRetinaPixel);
    [self.view addSubview:_inputBackgroundView];
    
    _inputBackgroundView.userInteractionEnabled = true;
    [_inputBackgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(inputBackgroundTapped:)]];
    
    _countryCodeField = [[UITextField alloc] init];
    _countryCodeField.font = TGSystemFontOfSize(20.0f);
    _countryCodeField.backgroundColor = [UIColor clearColor];
    _countryCodeField.text = @"+";
    _countryCodeField.textAlignment = NSTextAlignmentCenter;
    _countryCodeField.keyboardType = UIKeyboardTypeNumberPad;
    _countryCodeField.delegate = self;
    _countryCodeField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _countryCodeField.frame = CGRectMake(14.0f, _inputBackgroundView.frame.origin.y + 1.0f + TGRetinaPixel, 68.0f, 56.0f);
    [self.view addSubview:_countryCodeField];
    
    _phoneField = [[TGBackspaceTextField alloc] init];
    _phoneField.delegate = self;
    _phoneField.font = TGSystemFontOfSize(20.0f);
    _phoneField.backgroundColor = [UIColor clearColor];
    _phoneField.placeholder = TGLocalized(@"Login.PhonePlaceholder");
    _phoneField.keyboardType = UIKeyboardTypeNumberPad;
    _phoneField.delegate = self;
    _phoneField.placeholderColor = UIColorRGB(0xc7c7cd);
    _phoneField.placeholderFont = _phoneField.font;
    _phoneField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _phoneField.frame = CGRectMake(96.0f, _inputBackgroundView.frame.origin.y + 1.0f + TGRetinaPixel, screenSize.width - 96.0f - 10.0f, 56.0f);
    [self.view addSubview:_phoneField];
    
    CGFloat separatorHeight = TGIsRetina() ? 0.5f : 1.0f;
    _separatorView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, _grayBackground.frame.size.height, _grayBackground.frame.size.width, separatorHeight)];
    _separatorView.backgroundColor = UIColorRGB(0xc8c7cc);
    [self.view addSubview:_separatorView];
    
    //if (![self _updateControllerInset:false])
        [self updateInterface:self.interfaceOrientation];
    
    NSString *countryId = nil;
    
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [networkInfo subscriberCellularProvider];
    if (carrier != nil)
    {
        NSString *mcc = [carrier isoCountryCode];
        if (mcc != nil)
            countryId = mcc;
    }
    if (countryId == nil)
    {
        NSLocale *locale = [NSLocale currentLocale];
        countryId = [locale objectForKey:NSLocaleCountryCode];
    }
    
    int code = 0;
    [TGLoginCountriesController countryNameByCountryId:countryId code:&code];
    if (code == 0)
        code = 1;
    
    _countryCodeField.text = [NSString stringWithFormat:@"+%d", code];
    
    _shadeView = [[UIView alloc] initWithFrame:self.view.bounds];
    _shadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _shadeView.hidden = true;
    [self.view addSubview:_shadeView];
    
    [self updatePhoneTextForCountryFieldText:_countryCodeField.text];
    
    [self updateCountry];
    
    if (_presetPhoneNumber.length == 0 || _presetPhoneCountry.length == 0)
    {
        if (iosMajorVersion() >= 7)
        {
            NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
            _keyValueStoreChangeProxy = [[TGObserverProxy alloc] initWithTarget:self targetSelector:@selector(keyValueStoreChanged:) name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:store];
            
            NSString *phoneNumber = [TGPhoneUtils cleanPhone:[store objectForKey:@"telegram_currentPhoneNumber"]];
            if (phoneNumber.length != 0)
            {
                for (int i = 0; i < (int)phoneNumber.length; i++)
                {
                    int countryCode = [[phoneNumber substringWithRange:NSMakeRange(0, phoneNumber.length - i)] intValue];
                    NSString *countryName = [TGLoginCountriesController countryNameByCode:countryCode];
                    if (countryName != nil)
                    {
                        _presetPhoneCountry = [[NSString alloc] initWithFormat:@"+%@", [phoneNumber substringWithRange:NSMakeRange(0, phoneNumber.length - i)]];
                        _presetPhoneNumber = [phoneNumber substringFromIndex:phoneNumber.length - i];
                    }
                }
            }
        }
    }
    
    [self _applyPresetNumber];
}

- (void)keyValueStoreChanged:(NSNotification *)__unused notification
{
    if (iosMajorVersion() >= 7)// && !_editedText)
    {
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        NSString *phoneNumber = [TGPhoneUtils cleanPhone:[store objectForKey:@"telegram_currentPhoneNumber"]];
        if (phoneNumber.length != 0)
        {
            for (int i = 0; i < (int)phoneNumber.length; i++)
            {
                int countryCode = [[phoneNumber substringWithRange:NSMakeRange(0, phoneNumber.length - i)] intValue];
                NSString *countryName = [TGLoginCountriesController countryNameByCode:countryCode];
                if (countryName != nil)
                {
                    NSString *presetPhoneCountry = [[NSString alloc] initWithFormat:@"+%@", [phoneNumber substringWithRange:NSMakeRange(0, phoneNumber.length - i)]];
                    NSString *presetPhoneNumber = [phoneNumber substringFromIndex:phoneNumber.length - i];
                    
                    if (!TGStringCompare(_presetPhoneCountry, presetPhoneCountry) || !TGStringCompare(_presetPhoneNumber, presetPhoneNumber))
                    {
                        _presetPhoneCountry = presetPhoneCountry;
                        _presetPhoneNumber = presetPhoneNumber;
                        
                        [self _applyPresetNumber];
                    }
                }
            }
        }
    }
}

- (void)performClose
{
    [ActionStageInstance() removeWatcher:self];
    [self setInProgress:false];
    
    [self.navigationController popViewControllerAnimated:true];
}

- (void)doUnloadView
{
    _countryCodeField.delegate = nil;
    _phoneField.delegate = nil;
}

- (void)viewDidUnload
{
    [self doUnloadView];
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (BOOL)shouldAutorotate
{
    return true;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.view setNeedsLayout];
    
    [self updateInterface:self.interfaceOrientation];
    
    [super viewWillAppear:animated];
}

- (void)controllerInsetUpdated:(UIEdgeInsets)previousInset
{
    [super controllerInsetUpdated:previousInset];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self updateInterface:toInterfaceOrientation];
}

- (void)updateInterface:(UIInterfaceOrientation)orientation
{
    CGSize screenSize = [self referenceViewSizeForOrientation:orientation];

    CGFloat topOffset = 0.0f;
    CGFloat titleLabelOffset = 0.0f;
    CGFloat noticeLabelOffset = 0.0f;
    CGFloat countryButtonOffset = 0.0f;
    CGFloat sideInset = 0.0f;
    
    if (TGIsPad())
    {
        if (UIInterfaceOrientationIsPortrait(orientation))
        {
            topOffset = 305.0f;
            titleLabelOffset = topOffset - 108.0f;
        }
        else
        {
            topOffset = 135.0f;
            titleLabelOffset = topOffset - 78.0f;
        }
        
        noticeLabelOffset = topOffset + 143.0f;
        countryButtonOffset = topOffset;
        sideInset = 130.0f;
    }
    else
    {
        topOffset = [TGViewController isWidescreen] ? 131.0f : 64.0f;
        titleLabelOffset = [TGViewController isWidescreen] ? 71.0f : 48.0f;
        noticeLabelOffset = [TGViewController isWidescreen] ? (screenSize.height>568.0f ? 274.0f:254.0f) : 188.0f;
        countryButtonOffset = [TGViewController isWidescreen] ? 131.0f : 64.0f;
    }
    
    _grayBackground.frame = CGRectMake(0.0f, 0.0f, screenSize.width, topOffset);
    _separatorView.frame = CGRectMake(0.0f, topOffset, screenSize.width, _separatorView.frame.size.height);
    
    _titleLabel.frame = CGRectMake(CGFloor((screenSize.width - _titleLabel.frame.size.width) / 2), titleLabelOffset, _titleLabel.frame.size.width, _titleLabel.frame.size.height);
    
    CGSize noticeSize = [_noticeLabel sizeThatFits:CGSizeMake(278.0f, CGFLOAT_MAX)];
    _noticeLabel.frame = CGRectMake(CGFloor((screenSize.width - noticeSize.width) / 2.0f), noticeLabelOffset, noticeSize.width, noticeSize.height);
    
    _countryButton.frame = CGRectMake(sideInset, countryButtonOffset, screenSize.width - sideInset * 2.0f, _countryButton.frame.size.height);
    
    _inputBackgroundView.frame = CGRectMake(sideInset - (TGIsPad() ? 15.0f : 0.0f), _countryButton.frame.origin.y + 57.0f, screenSize.width - sideInset * 2.0f + (TGIsPad() ? 15.0f : 0.0f), _inputBackgroundView.frame.size.height);
    
    _countryCodeField.frame = CGRectMake(14.0f + sideInset - (TGIsPad() ? 15.0f : 0.0f), _inputBackgroundView.frame.origin.y + 1.0f + TGRetinaPixel, 68.0f, 56.0f);
    
    _phoneField.frame = CGRectMake(96.0f + sideInset - (TGIsPad() ? 15.0f : 0.0f), _inputBackgroundView.frame.origin.y + 1.0f + TGRetinaPixel, screenSize.width - 96.0f - 10.0f - sideInset * 2.0f, 56.0f);
}

- (void)setInProgress:(bool)inProgress
{
    if (_inProgress != inProgress)
    {
        _inProgress = inProgress;
        
        if (inProgress)
        {
            _progressWindow = [[TGProgressWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            [_progressWindow show:true];
            
            _shadeView.hidden = false;
        }
        else
        {
            if (_progressWindow != nil)
            {
                [_progressWindow dismiss:true];
                _progressWindow = nil;
            }
            
            _shadeView.hidden = true;
        }
    }
}

#pragma mark -

- (void)textFieldDidHitLastBackspace
{
    [_countryCodeField becomeFirstResponder];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (_inProgress)
        return false;
    
    _editedText = true;
    
    if (textField == _countryCodeField)
    {
        int length = (int)string.length;
        unichar replacementCharacters[length];
        int filteredLength = 0;
        
        for (int i = 0; i < length; i++)
        {
            unichar c = [string characterAtIndex:i];
            if (c >= '0' && c <= '9')
                replacementCharacters[filteredLength++] = c;
        }
        
        if (filteredLength == 0 && (range.length == 0 || range.location == 0))
            return false;
        
        if (range.location == 0)
            range.location++;
        
        NSString *replacementString = [[NSString alloc] initWithCharacters:replacementCharacters length:filteredLength];
        
        NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:replacementString];
        if (newText.length > 5)
        {
            for (int i = 0; i < (int)newText.length - 1; i++)
            {
                int countryCode = [[newText substringWithRange:NSMakeRange(1, newText.length - 1 - i)] intValue];
                NSString *countryName = [TGLoginCountriesController countryNameByCode:countryCode];
                if (countryName != nil)
                {
                    _phoneField.text = [self filterPhoneText:[[NSString alloc] initWithFormat:@"%@%@", [newText substringFromIndex:newText.length - i], _phoneField.text]];
                    newText = [newText substringToIndex:newText.length - i];
                    [_phoneField becomeFirstResponder];
                }
            }
            
            if (newText.length > 5)
                newText = [newText substringToIndex:5];
        }
        
        textField.text = newText;
        
        [self updatePhoneTextForCountryFieldText:newText];
        
        [self updateCountry];
        
        return false;
    }
    else if (textField == _phoneField)
    {
        if (true)
        {
            int stringLength = (int)string.length;
            unichar replacementCharacters[stringLength];
            int filteredLength = 0;
            
            for (int i = 0; i < stringLength; i++)
            {
                unichar c = [string characterAtIndex:i];
                if (c >= '0' && c <= '9')
                    replacementCharacters[filteredLength++] = c;
            }
            
            NSString *replacementString = [[NSString alloc] initWithCharacters:replacementCharacters length:filteredLength];
            
            unichar rawNewString[replacementString.length];
            int rawNewStringLength = 0;
            
            int replacementLength = (int)replacementString.length;
            for (int i = 0; i < replacementLength; i++)
            {
                unichar c = [replacementString characterAtIndex:i];
                if ((c >= '0' && c <= '9'))
                    rawNewString[rawNewStringLength++] = c;
            }
            
            NSString *string = [[NSString alloc] initWithCharacters:rawNewString length:rawNewStringLength];
            
            NSMutableString *rawText = [[NSMutableString alloc] initWithCapacity:16];
            NSString *currentText = textField.text;
            int length = (int)currentText.length;
            
            int originalLocation = (int)range.location;
            int originalEndLocation = (int)range.location + (int)range.length;
            int endLocation = originalEndLocation;
            
            for (int i = 0; i < length; i++)
            {
                unichar c = [currentText characterAtIndex:i];
                if ((c >= '0' && c <= '9'))
                    [rawText appendString:[[NSString alloc] initWithCharacters:&c length:1]];
                else
                {
                    if (originalLocation > i)
                    {
                        if (range.location > 0)
                            range.location--;
                    }
                    
                    if (originalEndLocation > i)
                        endLocation--;
                }
            }
            
            int newLength = endLocation - (int)range.location;
            if (newLength == 0 && range.length == 1 && range.location > 0)
            {
                range.location--;
                newLength = 1;
            }
            if (newLength < 0)
                return false;
            
            range.length = newLength;
            
            @try
            {
                int caretPosition = (int)range.location + (int)string.length;
                
                [rawText replaceCharactersInRange:range withString:string];
                
                NSString *countryCodeText = _countryCodeField.text.length > 1 ? _countryCodeField.text : @"";
                
                NSString *formattedText = [TGPhoneUtils formatPhone:[[NSString alloc] initWithFormat:@"%@%@", countryCodeText, rawText] forceInternational:false];
                if (countryCodeText.length > 1)
                {
                    int i = 0;
                    int j = 0;
                    while (i < (int)formattedText.length && j < (int)countryCodeText.length)
                    {
                        unichar c1 = [formattedText characterAtIndex:i];
                        unichar c2 = [countryCodeText characterAtIndex:j];
                        if (c1 == c2)
                            j++;
                        i++;
                    }
                    
                    formattedText = [formattedText substringFromIndex:i];
                    
                    i = 0;
                    while (i < (int)formattedText.length)
                    {
                        unichar c = [formattedText characterAtIndex:i];
                        if ((c == ')' && i != 0) || c == '(' || (c >= '0' && c <= '9'))
                            break;
                        
                        i++;
                    }
                    
                    formattedText = [self filterPhoneText:[formattedText substringFromIndex:i]];
                }
                
                int formattedTextLength = (int)formattedText.length;
                int rawTextLength = (int)rawText.length;
                
                int newCaretPosition = caretPosition;
                
                for (int j = 0, k = 0; j < formattedTextLength && k < rawTextLength; )
                {
                    unichar c1 = [formattedText characterAtIndex:j];
                    unichar c2 = [rawText characterAtIndex:k];
                    if (c1 != c2)
                        newCaretPosition++;
                    else
                        k++;
                    
                    if (k == caretPosition)
                    {
                        break;
                    }
                    
                    j++;
                }
                
                textField.text = formattedText;
                
                if (caretPosition >= (int)textField.text.length)
                    caretPosition = (int)textField.text.length;
                
                UITextPosition *startPosition = [textField positionFromPosition:textField.beginningOfDocument offset:newCaretPosition];
                UITextPosition *endPosition = [textField positionFromPosition:textField.beginningOfDocument offset:newCaretPosition];
                UITextRange *selection = [textField textRangeFromPosition:startPosition toPosition:endPosition];
                textField.selectedTextRange = selection;
            }
            @catch (NSException *e)
            {
                TGLog(@"%@", e);
            }
            
            return false;
        }
        else
        {
            int length = (int)string.length;
            unichar replacementCharacters[length];
            int filteredLength = 0;
            
            for (int i = 0; i < length; i++)
            {
                unichar c = [string characterAtIndex:i];
                if (c >= '0' && c <= '9')
                    replacementCharacters[filteredLength++] = c;
            }
            
            NSString *replacementString = [[NSString alloc] initWithCharacters:replacementCharacters length:filteredLength];
            
            NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:replacementString];
            if (newText.length > 19)
                newText = [newText substringToIndex:19];
            
            textField.text = newText;
            
            return false;
        }
    }
    
    return true;
}

- (NSString *)filterPhoneText:(NSString *)text
{
    int i = 0;
    while (i < (int)text.length)
    {
        unichar c = [text characterAtIndex:i];
        if ((c >= '0' && c <= '9'))
            return text;
        
        i++;
    }
    
    return @"";
}

- (void)updatePhoneTextForCountryFieldText:(NSString *)countryCodeText
{
    NSString *rawText = _phoneField.text;
    
    NSString *formattedText = [TGPhoneUtils formatPhone:[[NSString alloc] initWithFormat:@"%@%@", countryCodeText, rawText] forceInternational:false];
    if (countryCodeText.length > 1)
    {
        int i = 0;
        int j = 0;
        while (i < (int)formattedText.length && j < (int)countryCodeText.length)
        {
            unichar c1 = [formattedText characterAtIndex:i];
            unichar c2 = [countryCodeText characterAtIndex:j];
            if (c1 == c2)
                j++;
            i++;
        }
        
        formattedText = [formattedText substringFromIndex:i];
        
        i = 0;
        while (i < (int)formattedText.length)
        {
            unichar c = [formattedText characterAtIndex:i];
            if (c == '(' || c == ')' || (c >= '0' && c <= '9'))
                break;
            
            i++;
        }
        
        formattedText = [formattedText substringFromIndex:i];
        _phoneField.text = [self filterPhoneText:formattedText];
    }
    else
        _phoneField.text = [self filterPhoneText:[TGPhoneUtils formatPhone:[[NSString alloc] initWithFormat:@"%@", _phoneField.text] forceInternational:false]];
}

- (void)updateCountry
{
    int countryCode = [[_countryCodeField.text substringFromIndex:1] intValue];
    NSString *countryName = [TGLoginCountriesController countryNameByCode:countryCode];
    
    if (countryName != nil)
    {
        //[_countryButton setTitleColor:UIColorRGB(0xf0f0f0) forState:UIControlStateNormal];
        [_countryButton setTitle:countryName forState:UIControlStateNormal];
    }
    else
    {
        //[_countryButton setTitleColor:UIColorRGBA(0xf0f0f0, 0.7f) forState:UIControlStateNormal];
        [_countryButton setTitle:_countryCodeField.text.length <= 1 ? TGLocalized(@"Login.CountryCode") : TGLocalized(@"Login.InvalidCountryCode") forState:UIControlStateNormal];
    }
}

#pragma mark -

- (void)backgroundTapped:(UITapGestureRecognizer *)recognizer
{
    return;
    
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        [_countryCodeField resignFirstResponder];
        [_phoneField resignFirstResponder];
    }
}

- (void)inputBackgroundTapped:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        if ([recognizer locationInView:recognizer.view].x < _countryCodeField.frame.origin.x + _countryCodeField.frame.size.width)
            [_countryCodeField becomeFirstResponder];
        else
            [_phoneField becomeFirstResponder];
    }
}

- (void)shakeView:(UIView *)v originalX:(CGFloat)originalX
{
    CGRect r = v.frame;
    r.origin.x = originalX;
    CGRect originalFrame = r;
    CGRect rFirst = r;
    rFirst.origin.x = r.origin.x + 4;
    r.origin.x = r.origin.x - 4;
    
    v.frame = v.frame;
    
    [UIView animateWithDuration:0.05 delay:0.0 options:UIViewAnimationOptionAutoreverse animations:^
    {
        v.frame = rFirst;
    } completion:^(BOOL finished)
    {
        if (finished)
        {
            [UIView animateWithDuration:0.05 delay:0.0 options:(UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse) animations:^
            {
                [UIView setAnimationRepeatCount:3];
                v.frame = r;
            } completion:^(__unused BOOL finished)
            {
                v.frame = originalFrame;
            }];
        }
        else
            v.frame = originalFrame;
    }];
}

- (void)_commitNextButtonPressed
{
    if (_inProgress)
        return;
    
    if (_phoneField.text.length == 0 || _countryCodeField.text.length < 2)
    {
        //CGSize screenSize = [self referenceViewSizeForOrientation:self.interfaceOrientation];
        CGFloat sideInset = 0.0f;
        
        if (TGIsPad())
        {
            sideInset = 130.0f;
        }
        
        [self shakeView:_phoneField originalX:96.0f + sideInset];
        //[self shakeView:_inputBackgroundView originalX:_baseInputBackgroundViewFrame.origin.x];
        [self shakeView:_countryCodeField originalX:14.0f + sideInset];
        
        if (_countryCodeField.text.length < 2)
            [_countryCodeField becomeFirstResponder];
        else if (_phoneField.text.length == 0)
            [_phoneField becomeFirstResponder];
    }
    else
    {
        self.inProgress = true;
        
        static int actionIndex = 0;
        _currentActionIndex = actionIndex++;
        _phoneNumber = [NSString stringWithFormat:@"%@%@", [_countryCodeField.text substringFromIndex:1], _phoneField.text];
        [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/service/auth/sendCode/(%d)", _currentActionIndex] options:[NSDictionary dictionaryWithObjectsAndKeys:_phoneNumber, @"phoneNumber", nil] watcher:self];
    }
}

- (void)nextButtonPressed
{
    if (_inProgress)
        return;
    
    if (TGIsPad())
    {
        NSMutableString *string = [[NSMutableString alloc] initWithString:TGLocalized(@"Login.PadPhoneHelp")];
        NSRange range = [string rangeOfString:@"{number}"];
        if (range.location != NSNotFound)
        {
            NSString *phoneNumber = [NSString stringWithFormat:@"%@%@", [_countryCodeField.text substringFromIndex:1], _phoneField.text];
            [string replaceCharactersInRange:range withString:[TGPhoneUtils formatPhone:phoneNumber forceInternational:true]];
        }
        __weak TGLoginPhoneController *weakSelf = self;
        [[[TGAlertView alloc] initWithTitle:TGLocalized(@"Login.PadPhoneHelpTitle") message:string cancelButtonTitle:TGLocalized(@"Common.Cancel") okButtonTitle:TGLocalized(@"Common.OK") completionBlock:^(bool okButtonPressed)
        {
            if (okButtonPressed)
            {
                __strong TGLoginPhoneController *strongSelf = weakSelf;
                if (strongSelf != nil)
                {
                    [strongSelf _commitNextButtonPressed];
                }
            }
        }] show];
    }
    else
        [self _commitNextButtonPressed];
}

- (void)countryButtonPressed:(id)__unused sender
{
    TGLoginCountriesController *countriesController = [[TGLoginCountriesController alloc] init];
    countriesController.watcherHandle = _actionHandle;
    
    TGNavigationController *navigationController = [TGNavigationController navigationControllerWithRootController:countriesController];
    [self presentViewController:navigationController animated:true completion:nil];
}

- (void)termButtonPressed
{
    TGWebViewController *terms = [[TGWebViewController alloc] initWithUrl:DoveUserTermsUrl andType:WebViewControllerTypeLogin];
    [self.navigationController pushViewController:terms animated:YES];
}

#pragma mark -

- (void)actorCompleted:(int)resultCode path:(NSString *)path result:(id)result
{
    if ([path isEqualToString:[NSString stringWithFormat:@"/tg/service/auth/sendCode/(%d)", _currentActionIndex]])
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            self.inProgress = false;
            
            if (resultCode == ASStatusSuccess)
            {
                NSString *phoneCodeHash = [((SGraphObjectNode *)result).object objectForKey:@"phoneCodeHash"];
                
                NSTimeInterval phoneTimeout = (((SGraphObjectNode *)result).object)[@"callTimeout"] == nil ? 60 : [(((SGraphObjectNode *)result).object)[@"callTimeout"] intValue];
                
                bool messageSentToTelegram = [(((SGraphObjectNode *)result).object)[@"messageSentToTelegram"] intValue];
                
                [TGAppDelegateInstance saveLoginStateWithDate:(int)CFAbsoluteTimeGetCurrent() phoneNumber:[[NSString alloc] initWithFormat:@"%@|%@", _countryCodeField.text, _phoneField.text] phoneCode:nil phoneCodeHash:phoneCodeHash codeSentToTelegram:messageSentToTelegram firstName:nil lastName:nil photo:nil];
                
                [self.navigationController pushViewController:[[TGLoginCodeController alloc] initWithShowKeyboard:(_countryCodeField.isFirstResponder || _phoneField.isFirstResponder) phoneNumber:_phoneNumber phoneCodeHash:phoneCodeHash phoneTimeout:phoneTimeout messageSentToTelegram:messageSentToTelegram] animated:true];
            }
            else
            {
                NSString *errorText = TGLocalized(@"Login.UnknownError");
                
                if (resultCode == TGSendCodeErrorInvalidPhone)
                    errorText = TGLocalized(@"Login.InvalidPhoneError");
                else if (resultCode == TGSendCodeErrorFloodWait)
                    errorText = TGLocalized(@"Login.CodeFloodError");
                else if (resultCode == TGSendCodeErrorNetwork)
                    errorText = TGLocalized(@"Login.NetworkError");
                
                TGAlertView *alertView = [[TGAlertView alloc] initWithTitle:nil message:errorText delegate:nil cancelButtonTitle:TGLocalized(@"Common.OK") otherButtonTitles:nil];
                [alertView show];
            }
        });
    }
}

- (void)actionStageActionRequested:(NSString *)action options:(NSDictionary *)options
{
    if ([action isEqualToString:@"countryCodeSelected"])
    {
        [self dismissViewControllerAnimated:true completion:nil];
        
        if ([options objectForKey:@"code"] != nil)
        {
            //[_countryButton setTitleColor:UIColorRGB(0xf0f0f0) forState:UIControlStateNormal];
            [_countryButton setTitle:[options objectForKey:@"name"] forState:UIControlStateNormal];
            _countryCodeField.text = [NSString stringWithFormat:@"+%d", [[options objectForKey:@"code"] intValue]];
            
            [self updatePhoneTextForCountryFieldText:_countryCodeField.text];
        }
    }
}

@end