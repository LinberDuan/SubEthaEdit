//
//  StylePreferences.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Oct 07 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "StylePreferences.h"
#import "SyntaxStyle.h"
#import "DocumentModeManager.h"
#import "TableView.h"
#import "TextFieldCell.h"


@implementation StylePreferences

- (id) init {
    self = [super init];
    if (self) {
        I_baseStyleDictionary=[NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc {
    [I_baseStyleDictionary release];
    [super dealloc];
}

- (NSImage *)icon {
    return [NSImage imageNamed:@"StylePrefs"];
}

- (NSString *)iconLabel {
    return NSLocalizedString(@"StylePrefsIconLabel", @"Label displayed below tyle pref icon and used as window title.");
}

- (NSString *)identifier {
    return @"de.codingmonkeys.subethaedit.preferences.style";
}

- (NSString *)mainNibName {
    return @"StylePrefs";
}

- (void)adjustTableViewColumns:(NSNotification *)aNotification {
    float width=[[[O_stylesTableView enclosingScrollView] contentView] frame].size.width;
    width-=[O_stylesTableView intercellSpacing].width*3;
    float width2=width/2.;
    NSArray *columns=[O_stylesTableView tableColumns];
    [[columns objectAtIndex:0] setWidth:width2];
    [[columns objectAtIndex:1] setWidth:width2];
}

- (void)mainViewDidLoad {
    // Initialize user interface elements to reflect current preference settings
    [self changeMode:O_modePopUpButton];
    
    // Set tableview to non highlighting cells
    [[[O_stylesTableView tableColumns] objectAtIndex:0] setDataCell:[[TextFieldCell new] autorelease]];
    [[[O_stylesTableView tableColumns] objectAtIndex:1] setDataCell:[[TextFieldCell new] autorelease]];
    
    [[O_stylesTableView enclosingScrollView] setPostsFrameChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustTableViewColumns:) name:NSViewFrameDidChangeNotification object:[O_stylesTableView enclosingScrollView]];
    NSMutableAttributedString *string=[[O_italicButton attributedTitle] mutableCopy];
    [string addAttribute:NSObliquenessAttributeName value:[NSNumber numberWithFloat:.2] range:NSMakeRange(0,[[string string] length])];
    [O_italicButton setAttributedTitle:[string autorelease]];
    [self adjustTableViewColumns:nil];
}

- (void)updateBackgroundColor {
    NSDictionary *baseStyle=[[[O_modeController content] syntaxStyle] styleForKey:SyntaxStyleBaseIdentifier];
    [O_stylesTableView setLightBackgroundColor:[baseStyle objectForKey:@"background-color"]];
    [O_stylesTableView setDarkBackgroundColor: [baseStyle objectForKey:@"inverted-background-color"]];
    [O_stylesTableView reloadData];
}

- (IBAction)validateDefaultsState:(id)aSender {
    BOOL useDefault=[[[O_modePopUpButton selectedMode] defaultForKey:DocumentModeUseDefaultStylePreferenceKey] boolValue];
    [O_defaultStyleButton setHidden:[[I_currentSyntaxStyle documentMode] isBaseMode]];
    if (O_defaultStyleButton !=aSender) {
        [O_defaultStyleButton setState:useDefault?NSOnState:NSOffState];
    }

    [O_stylesTableView setDisableFirstRow:useDefault];
    
    if (useDefault) {
        [O_modeController setContent:[DocumentModeManager baseMode]];
        [O_stylesTableView deselectRow:0];
    } else {
        [O_modeController setContent:[O_modePopUpButton selectedMode]];
    }
    NSDictionary *baseStyle=[[[O_modeController content] syntaxStyle] styleForKey:SyntaxStyleBaseIdentifier];
    [O_backgroundColorWell         setColor:[baseStyle objectForKey:@"background-color"]         ];
    [O_invertedBackgroundColorWell setColor:[baseStyle objectForKey:@"inverted-background-color"]]; 
    [self updateBackgroundColor];
    [O_lightBackgroundButton       setEnabled:!useDefault];
    [O_darkBackgroundButton        setEnabled:!useDefault];
    [O_backgroundColorWell         setEnabled:!useDefault];
    [O_invertedBackgroundColorWell setEnabled:!useDefault];
}

- (IBAction)changeDefaultState:(id)aSender {
    BOOL useDefault = ([aSender state]==NSOnState);
    [[[O_modePopUpButton selectedMode] defaults] setObject:[NSNumber numberWithBool:useDefault] forKey:DocumentModeUseDefaultStylePreferenceKey];
    [self validateDefaultsState:aSender];
}

#define BUFFERSIZE 40

- (NSEnumerator *)selectedStylesEnumerator {
    NSMutableArray *styleArray=[NSMutableArray array];
    unsigned int indexBuffer[BUFFERSIZE];
    NSArray *allKeys=[I_currentSyntaxStyle allKeys];
    NSIndexSet *selectedRows=[O_stylesTableView selectedRowIndexes];
    NSRange range=NSMakeRange(0,NSNotFound);
    int count;
    while ((count=[selectedRows getIndexes:indexBuffer maxCount:BUFFERSIZE inIndexRange:&range])) {
        int i=0;
        for (i=0;i<count;i++) {
            [styleArray addObject:[I_currentSyntaxStyle styleForKey:[allKeys objectAtIndex:indexBuffer[i]]]];
        }
    }
    
    return [styleArray objectEnumerator];
}

#define UNITITIALIZED -5
#define MANY  -4

- (void)updateInspector {
    int bold=UNITITIALIZED, italic=UNITITIALIZED, manyColors=NO,manyInvertedColors=NO;
    unsigned int indexBuffer[BUFFERSIZE];
    NSColor *color=nil,*invertedColor=nil;
    NSArray *allKeys=[I_currentSyntaxStyle allKeys];
    NSIndexSet *selectedRows=[O_stylesTableView selectedRowIndexes];
    NSRange range=NSMakeRange(0,NSNotFound);
    int count;
    while ((count=[selectedRows getIndexes:indexBuffer maxCount:BUFFERSIZE inIndexRange:&range])) {
        int i=0;
        for (i=0;i<count;i++) {
            unsigned int index=indexBuffer[i];
            NSString *key=[allKeys objectAtIndex:index];
            NSDictionary *style=[I_currentSyntaxStyle styleForKey:key];
            if (bold!=MANY) {
                BOOL innerBold=([[style objectForKey:@"font-trait"] unsignedIntValue] & NSBoldFontMask);
                if (bold==UNITITIALIZED) {
                    bold=innerBold;
                } else {
                    if (bold!=innerBold) {
                        bold=MANY;
                    }
                }
            }
            if (italic!=MANY) {
                BOOL innerItalic=([[style objectForKey:@"font-trait"] unsignedIntValue] & NSItalicFontMask);
                if (italic==UNITITIALIZED) {
                    italic=innerItalic;
                } else {
                    if (italic!=innerItalic) {
                        italic=MANY;
                    }
                }
            }
            if (!manyColors) {
                NSColor *innerColor=[style objectForKey:@"color"];
                if (!color) {
                    color=innerColor;
                } else {
                    if (![[color HTMLString] isEqualToString:[innerColor HTMLString]]) {
                        manyColors=YES;
                    }
                }
            }
            if (!manyInvertedColors) {
                NSColor *innerColor=[style objectForKey:@"inverted-color"];
                if (!invertedColor) {
                    invertedColor=innerColor;
                } else {
                    if (![[invertedColor HTMLString] isEqualToString:[innerColor HTMLString]]) {
                        manyInvertedColors=YES;
                    }
                }
            }
        }
    }
    
    [O_italicButton      setEnabled:(bold!=UNITITIALIZED)];
    [O_boldButton        setEnabled:(bold!=UNITITIALIZED)];
    [O_colorWell         setEnabled:(bold!=UNITITIALIZED)];
    [O_invertedColorWell setEnabled:(bold!=UNITITIALIZED)];
    if (bold!=UNITITIALIZED) {
        [O_italicButton setAllowsMixedState:italic==MANY];
        [O_italicButton setState:italic==MANY?NSMixedState:(italic?NSOnState:NSOffState)];
        [O_boldButton   setAllowsMixedState:bold==MANY];
        [O_boldButton   setState:bold  ==MANY?NSMixedState:(bold  ?NSOnState:NSOffState)];
        [O_colorWell setColor:color];
        [O_invertedColorWell setColor:invertedColor];
    }
    // sad but needed...
    [[O_boldButton superview] setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark IBActions

- (IBAction)changeMode:(id)aSender {
    DocumentMode *newMode=[aSender selectedMode];
    NSDictionary *fontAttributes = [newMode defaultForKey:DocumentModeFontAttributesPreferenceKey];
    NSFont *font=[NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:11.];
    if (!font) font=[NSFont userFixedPitchFontOfSize:11.];
    [self setBaseFont:font];
    I_currentSyntaxStyle=[newMode syntaxStyle];
    [O_stylesTableView reloadData];
    [O_stylesTableView selectRow:0 byExtendingSelection:NO];
    [self validateDefaultsState:aSender];
}

- (IBAction)changeLightBackgroundColor:(id)aSender {
    NSMutableDictionary *baseStyle=[I_currentSyntaxStyle styleForKey:SyntaxStyleBaseIdentifier];
    [baseStyle setObject:[aSender color] forKey:@"background-color"];
    [self updateBackgroundColor];
}

- (IBAction)changeDarkBackgroundColor:(id)aSender {
    NSMutableDictionary *baseStyle=[I_currentSyntaxStyle styleForKey:SyntaxStyleBaseIdentifier];
    [baseStyle setObject:[aSender color] forKey:@"inverted-background-color"];
    [self updateBackgroundColor];
}

- (void)setKey:(NSString *)aKey ofSelectedStylesToObject:(id)anObject {
    NSMutableDictionary *style=nil;
    NSEnumerator *selectedStyles=[self selectedStylesEnumerator];
    while ((style=[selectedStyles nextObject])) {
        [style setObject:anObject forKey:aKey];
    }
    [O_stylesTableView reloadData];
}

- (IBAction)changeLightForegroundColor:(id)aSender {
    [self setKey:@"color" ofSelectedStylesToObject:[aSender color]];
}

- (IBAction)changeDarkForegroundColor:(id)aSender {
    [self setKey:@"inverted-color" ofSelectedStylesToObject:[aSender color]];
}

- (void)setTrait:(NSFontTraitMask)aTrait ofSelectedStylesTo:(BOOL)aState {
    NSMutableDictionary *style=nil;
    NSEnumerator *selectedStyles=[self selectedStylesEnumerator];
    while ((style=[selectedStyles nextObject])) {
        NSFontTraitMask traits=[[style objectForKey:@"font-trait"] unsignedIntValue];
        BOOL currentState = traits & aTrait;
        if (aState && !currentState) {
            traits = traits | aTrait;
        } else if (!aState && currentState) {
            traits = traits & (~aTrait);
        }
        [style setObject:[NSNumber numberWithUnsignedInt:traits] forKey:@"font-trait"];
    }
    [O_stylesTableView reloadData];
}

- (IBAction)changeFontTraitItalic:(id)aSender {
    [aSender setAllowsMixedState:NO];
    [self setTrait:NSItalicFontMask ofSelectedStylesTo:[aSender state]==NSOnState];
}

- (IBAction)changeFontTraitBold:(id)aSender {
    [aSender setAllowsMixedState:NO];
    [self setTrait:NSBoldFontMask ofSelectedStylesTo:[aSender state]==NSOnState];
}

- (IBAction)import:(id)aSender {
    NSOpenPanel *openPanel=[NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setRequiredFileType:@"seestyle"];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setExtensionHidden:NO];
    [openPanel beginSheetForDirectory:nil file:nil 
               types:[NSArray arrayWithObject:@"seestyle"] 
               modalForWindow:[O_stylesTableView window] 
               modalDelegate:self 
               didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
               contextInfo:nil];
}

- (void)openPanelDidEnd:(NSOpenPanel *)aPanel returnCode:(int)aReturnCode contextInfo:(void *)contextInfo {
    NSString *filename=[aPanel filename];
    if (aReturnCode==NSOKButton) {
        NSArray *styleArray=[SyntaxStyle syntaxStylesWithXMLFile:filename];
        NSEnumerator *styles=[styleArray objectEnumerator];
        SyntaxStyle *style=nil;
        while ((style = [styles nextObject])) {
            [[style documentMode] setSyntaxStyle:style];
        }
        style=[styleArray lastObject];
        if (style) {
            [O_modePopUpButton setSelectedMode:[style documentMode]];
            [self changeMode:O_modePopUpButton];
        }
    }
}

- (IBAction)export:(id)aSender {
    NSSavePanel *savePanel=[NSSavePanel savePanel];
    [savePanel setPrompt:NSLocalizedString(@"ExportPrompt",@"Text on the active SavePanel Button in the export sheet")];
    [savePanel setCanCreateDirectories:YES];
    [savePanel setExtensionHidden:NO];
    [savePanel setAllowsOtherFileTypes:YES];
    [savePanel setTreatsFilePackagesAsDirectories:YES];
    [savePanel setRequiredFileType:@"seestyle"];
    [savePanel beginSheetForDirectory:nil 
        file:[[[[[I_currentSyntaxStyle documentMode]  documentModeIdentifier] componentsSeparatedByString:@"."] lastObject] stringByAppendingPathExtension:@"seestyle"] 
        modalForWindow:[O_stylesTableView window] 
        modalDelegate:self 
        didEndSelector:@selector(exportSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)exportSheetDidEnd:(NSSavePanel *)aPanel returnCode:(int)aReturnCode contextInfo:(void *)aContextInfo {
    if (aReturnCode==NSOKButton) {
        [[[I_currentSyntaxStyle xmlFileRepresentation] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO] writeToFile:[aPanel filename] atomically:YES];
    }
}

- (IBAction)revertToMode:(id)aSender {
    DocumentMode *mode=[I_currentSyntaxStyle documentMode];
    [mode setSyntaxStyle:[[[mode defaultSyntaxStyle] copy] autorelease]];
    [self changeMode:O_modePopUpButton];
}


- (void)didUnselect {
    // Save preferences
}

- (void)setBaseFont:(NSFont *)aFont {
    [I_baseFont autorelease];
     I_baseFont = [aFont retain];
}

- (NSFont *)baseFont {
    return I_baseFont;
}

#pragma mark -
#pragma mark TableView DataSource
- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [[I_currentSyntaxStyle allKeys] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)aRow {
    BOOL useDefault=[[[O_modePopUpButton selectedMode] defaultForKey:DocumentModeUseDefaultStylePreferenceKey] boolValue];
    NSString *key=[[I_currentSyntaxStyle allKeys] objectAtIndex:aRow];
    NSDictionary *style=[(useDefault && aRow==0)?([[DocumentModeManager baseMode] syntaxStyle]):I_currentSyntaxStyle styleForKey:key];
    NSString *localizedString=[I_currentSyntaxStyle localizedStringForKey:key];
    NSFont *font=[self baseFont];
    NSFontManager *fontManager=[NSFontManager sharedFontManager];
    NSFontTraitMask traits=[[style objectForKey:@"font-trait"] unsignedIntValue];
    if (traits & NSBoldFontMask) {
        font=[fontManager convertFont:font toHaveTrait:NSBoldFontMask];
    }
    if (traits & NSItalicFontMask) {
        font=[fontManager convertFont:font toHaveTrait:NSItalicFontMask];
    }
    static NSMutableParagraphStyle *s_paragraphStyle=nil;
    if (!s_paragraphStyle) {
        s_paragraphStyle=[[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [s_paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    }
    NSDictionary *attributes=[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,
        [[aTableColumn identifier]isEqualToString:@"light"]?[style objectForKey:@"color"]:[style objectForKey:@"inverted-color"],NSForegroundColorAttributeName,
        s_paragraphStyle,NSParagraphStyleAttributeName,
        nil];
    return [[[NSAttributedString alloc] initWithString:localizedString attributes:attributes] autorelease];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self updateInspector];
}

#pragma mark TableView Delegate

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex {
    BOOL useDefault=[[[O_modePopUpButton selectedMode] defaultForKey:DocumentModeUseDefaultStylePreferenceKey] boolValue];
    if (rowIndex==0 && useDefault) {
        return NO;
    }
    return YES;
}

@end