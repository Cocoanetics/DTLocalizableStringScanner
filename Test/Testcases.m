
NSLocalizedString(@"Accounts", nil);
NSLocalizedStringWithDefaultValue(@"A Key %@ %@", nil, nil, @"Default Value %@ %@", nil);

NSLocalizedString(@"%[one, two] %[A, B]", @"predicate test");


// from Adium
// note: AILocalizedString replaced with NSLocalizedString
        [tableView_accountList accessibilitySetOverrideValue:NSLocalizedString(@"Accounts", nil)
                                                                                        forAttribute:NSAccessibilityRoleDescriptionAttribute];

#define CONTACT_NAME_MENU_TITLE         NSLocalizedString(@"Contact Name Format",nil)
#define ALIAS                                           NSLocalizedString(@"Alias",nil)
#define ALIAS_SCREENNAME                        NSLocalizedString(@"Alias (User Name)",nil)
#define SCREENNAME_ALIAS                        NSLocalizedString(@"User Name (Alias)",nil)
#define SCREENNAME                                      NSLocalizedString(@"User Name",nil)

                                [textField_horizontalWidthText setLocalizedString:NSLocalizedString(@"Maximum Width:",nil)];

        menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Authorization Requests",nil, [NSBundle bundleForClass:[AIAuthorizationRequestsWindowController class]], nil)
                                                                                  target:self
                                                                                  action:@selector(openAuthorizationWindow:)
                                                                   keyEquivalent:@""];

        NSString *errMsg = NSLocalizedStringWithDefaultValue(@"AsyncSocketCFSocketError",
                                                                                                                 @"AsyncSocket", [NSBundle mainBundle],
                                                                                                                 @"General CFSocket error", nil);
        
        NSDictionary *info = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];


                                if ([[menuItem title] isEqualToString:NSLocalizedStringFromTableInBundle(@"Open Link", nil, [NSBundle bundleForClass:[WebView class]], nil)])
                                        [webViewMenuItems removeObjectIdenticalTo:menuItem];                                    
                        }



