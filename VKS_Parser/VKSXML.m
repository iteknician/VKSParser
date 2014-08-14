// ================================================================================================

//  VKS_Parser

#import "VKSXML.h"

// ================================================================================================
// Private methods
// ================================================================================================
@interface VKSXML (Private)
+ (NSString *) errorTextForCode:(int)code;
+ (NSError *) errorWithCode:(int)code;
+ (NSError *) errorWithCode:(int)code userInfo:(NSDictionary *)userInfo;
- (void) decodeBytes;
- (int) allocateBytesOfLength:(long)length error:(NSError **)error;
- (VKSXMLElement*) nextAvailableElement;
- (VKSXMLAttribute*) nextAvailableAttribute;
@end

// ================================================================================================
// Public Implementation
// ================================================================================================
@implementation VKSXML

@synthesize rootXMLElement;

+ (id)newVKSXMLWithXMLString:(NSString*)aXMLString {
	return [[VKSXML alloc] initWithXMLString:aXMLString];
}

+ (id)newVKSXMLWithXMLString:(NSString*)aXMLString error:(NSError *__autoreleasing *)error {
	return [[VKSXML alloc] initWithXMLString:aXMLString error:error];
}

+ (id)newVKSXMLWithXMLData:(NSData*)aData {
	return [[VKSXML alloc] initWithXMLData:aData];
}

+ (id)newVKSXMLWithXMLData:(NSData*)aData error:(NSError *__autoreleasing *)error {
	return [[VKSXML alloc] initWithXMLData:aData error:error];
}

+ (id)newVKSXMLWithXMLFile:(NSString*)aXMLFile {
	return [[VKSXML alloc] initWithXMLFile:aXMLFile];
}

+ (id)newVKSXMLWithXMLFile:(NSString*)aXMLFile error:(NSError *__autoreleasing *)error {
	return [[VKSXML alloc] initWithXMLFile:aXMLFile error:error];
}

+ (id)newVKSXMLWithXMLFile:(NSString*)aXMLFile fileExtension:(NSString*)aFileExtension {
	return [[VKSXML alloc] initWithXMLFile:aXMLFile fileExtension:aFileExtension];
}

+ (id)newVKSXMLWithXMLFile:(NSString*)aXMLFile fileExtension:(NSString*)aFileExtension error:(NSError *__autoreleasing *)error {
	return [[VKSXML alloc] initWithXMLFile:aXMLFile fileExtension:aFileExtension error:error];
}

- (id)init {
	self = [super init];
	if (self != nil) {
		rootXMLElement = nil;
		
		currentElementBuffer = 0;
		currentAttributeBuffer = 0;
		
		currentElement = 0;
		currentAttribute = 0;		
		
		bytes = 0;
		bytesLength = 0;
	}
	return self;
}
- (id)initWithXMLString:(NSString*)aXMLString {
    NSError *error = nil;
    return [self initWithXMLString:aXMLString error:&error];
}

- (id)initWithXMLString:(NSString*)aXMLString error:(NSError *__autoreleasing *)error {
	self = [self init];
	if (self != nil) {
		
        
        // allocate memory for byte array
        int result = [self allocateBytesOfLength:[aXMLString lengthOfBytesUsingEncoding:NSUTF8StringEncoding] error:error];
        
        // if an error occured, return
        if (result != D_VKSXML_SUCCESS) 
            return self;
        
		// copy string to byte array
		[aXMLString getBytes:bytes maxLength:bytesLength usedLength:0 encoding:NSUTF8StringEncoding options:NSStringEncodingConversionAllowLossy range:NSMakeRange(0, bytesLength) remainingRange:nil];
		
		// set null terminator at end of byte array
		bytes[bytesLength] = 0;
		
		// decode xml data
		[self decodeBytes];
        
        // Check for root element
        if (error && !*error && !self.rootXMLElement) {
            *error = [VKSXML errorWithCode:D_VKSXML_DECODE_FAILURE];
        }
	}
	return self;
}

- (id)initWithXMLData:(NSData*)aData {
    NSError *error = nil;
    return [self initWithXMLData:aData error:&error];
}

- (id)initWithXMLData:(NSData*)aData error:(NSError **)error {
    self = [self init];
    if (self != nil) {
		// decode aData
		[self decodeData:aData withError:error];
    }
    
    return self;
}

- (id)initWithXMLFile:(NSString*)aXMLFile {
    NSError *error = nil;
    return [self initWithXMLFile:aXMLFile error:&error];
}

- (id)initWithXMLFile:(NSString*)aXMLFile error:(NSError **)error {
    NSString * filename = [aXMLFile stringByDeletingPathExtension];
    NSString * extension = [aXMLFile pathExtension];
    
    self = [self initWithXMLFile:filename fileExtension:extension error:error];
	if (self != nil) {
        
	}
	return self;
}

- (id)initWithXMLFile:(NSString*)aXMLFile fileExtension:(NSString*)aFileExtension {
    NSError *error = nil;
    return [self initWithXMLFile:aXMLFile fileExtension:aFileExtension error:&error];
}

- (id)initWithXMLFile:(NSString*)aXMLFile fileExtension:(NSString*)aFileExtension error:(NSError **)error {
	self = [self init];
	if (self != nil) {
        
        NSData * data;
        
        // Get the bundle that this class resides in. This allows to load resources from the app bundle when running unit tests.
        NSString * bundlePath = [[NSBundle bundleForClass:[self class]] pathForResource:aXMLFile ofType:aFileExtension];

        if (!bundlePath) {
            if (error) {
                NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[aXMLFile stringByAppendingPathExtension:aFileExtension], NSFilePathErrorKey, nil];
                *error = [VKSXML errorWithCode:D_VKSXML_FILE_NOT_FOUND_IN_BUNDLE userInfo:userInfo];
            }
        } else {
            SEL dataWithUncompressedContentsOfFile = NSSelectorFromString(@"dataWithUncompressedContentsOfFile:");
            
            // Get uncompressed file contents if VKSXML+Compression has been included
            if ([[NSData class] respondsToSelector:dataWithUncompressedContentsOfFile]) {
                
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                data = [[NSData class] performSelector:dataWithUncompressedContentsOfFile withObject:bundlePath];
                #pragma clang diagnostic pop   

            } else {
                data = [NSData dataWithContentsOfFile:bundlePath];
            }
            
            // decode data
            [self decodeData:data withError:error];
            
            // Check for root element
            if (error && !*error && !self.rootXMLElement) {
                *error = [VKSXML errorWithCode:D_VKSXML_DECODE_FAILURE];
            }
        }
	}
	return self;
}

- (int) decodeData:(NSData*)data {
    NSError *error = nil;
    return [self decodeData:data withError:&error];
}

- (int) decodeData:(NSData*)data withError:(NSError **)error {
    
    NSError *localError = nil;
    
    // allocate memory for byte array
    int result = [self allocateBytesOfLength:[data length] error:&localError];

    // ensure no errors during allocation
    if (result == D_VKSXML_SUCCESS) {
        
        // copy data to byte array
        [data getBytes:bytes length:bytesLength];
        
        // set null terminator at end of byte array
        bytes[bytesLength] = 0;
        
        // decode xml data
        [self decodeBytes];
        
        if (!self.rootXMLElement) {
            localError = [VKSXML errorWithCode:D_VKSXML_DECODE_FAILURE];
        }
    }

    // assign local error to pointer
    if (error) *error = localError;
    
    // return success or error code
    return localError == nil ? D_VKSXML_SUCCESS : (int)[localError code];
}

@end


// ================================================================================================
// Static Functions Implementation
// ================================================================================================

#pragma mark -
#pragma mark Static Functions implementation

@implementation VKSXML (StaticFunctions)

+ (NSString*) elementName:(VKSXMLElement*)aXMLElement {
	if (nil == aXMLElement->name) return @"";
	return [NSString stringWithCString:&aXMLElement->name[0] encoding:NSUTF8StringEncoding];
}

+ (NSString*) elementName:(VKSXMLElement*)aXMLElement error:(NSError **)error {
    // check for nil element
    if (nil == aXMLElement) {
        if (error) *error = [VKSXML errorWithCode:D_VKSXML_ELEMENT_IS_NIL];
        return @"";
    }
    
    // check for nil element name
    if (nil == aXMLElement->name || strlen(aXMLElement->name) == 0) {
        if (error) *error = [VKSXML errorWithCode:D_VKSXML_ELEMENT_NAME_IS_NIL];
        return @"";
    }
    
	return [NSString stringWithCString:&aXMLElement->name[0] encoding:NSUTF8StringEncoding];
}

+ (NSString*) attributeName:(VKSXMLAttribute*)aXMLAttribute {
	if (nil == aXMLAttribute->name) return @"";
	return [NSString stringWithCString:&aXMLAttribute->name[0] encoding:NSUTF8StringEncoding];
}

+ (NSString*) attributeName:(VKSXMLAttribute*)aXMLAttribute error:(NSError **)error {
    // check for nil attribute
    if (nil == aXMLAttribute) {
        if (error) *error = [VKSXML errorWithCode:D_VKSXML_ATTRIBUTE_IS_NIL];
        return @"";
    }
    
    // check for nil attribute name
    if (nil == aXMLAttribute->name) {
        if (error) *error = [VKSXML errorWithCode:D_VKSXML_ATTRIBUTE_NAME_IS_NIL];
        return @"";
    }
    
	return [NSString stringWithCString:&aXMLAttribute->name[0] encoding:NSUTF8StringEncoding];
}


+ (NSString*) attributeValue:(VKSXMLAttribute*)aXMLAttribute {
	if (nil == aXMLAttribute->value) return @"";
	return [NSString stringWithCString:&aXMLAttribute->value[0] encoding:NSUTF8StringEncoding];
}

+ (NSString*) attributeValue:(VKSXMLAttribute*)aXMLAttribute error:(NSError **)error {
    // check for nil attribute
    if (nil == aXMLAttribute) {
        if (error) *error = [VKSXML errorWithCode:D_VKSXML_ATTRIBUTE_IS_NIL];
        return @"";
    }
    
	return [NSString stringWithCString:&aXMLAttribute->value[0] encoding:NSUTF8StringEncoding];
}

+ (NSString*) textForElement:(VKSXMLElement*)aXMLElement {
	if (nil == aXMLElement->text) return @"";
	return [NSString stringWithCString:&aXMLElement->text[0] encoding:NSUTF8StringEncoding];
}

+ (NSString*) textForElement:(VKSXMLElement*)aXMLElement error:(NSError **)error {
    // check for nil element
    if (nil == aXMLElement) {
        if (error) *error = [VKSXML errorWithCode:D_VKSXML_ELEMENT_IS_NIL];
        return @"";
    }
    
    // check for nil text value
    if (nil == aXMLElement->text || strlen(aXMLElement->text) == 0) {
        if (error) *error = [VKSXML errorWithCode:D_VKSXML_ELEMENT_TEXT_IS_NIL];
        return @"";
    }
    
	return [NSString stringWithCString:&aXMLElement->text[0] encoding:NSUTF8StringEncoding];
}

+ (NSString*) valueOfAttributeNamed:(NSString *)aName forElement:(VKSXMLElement*)aXMLElement {
	const char * name = [aName cStringUsingEncoding:NSUTF8StringEncoding];
	NSString * value = nil;
	VKSXMLAttribute * attribute = aXMLElement->firstAttribute;
	while (attribute) {
		if (strlen(attribute->name) == strlen(name) && memcmp(attribute->name,name,strlen(name)) == 0) {
			value = [NSString stringWithCString:&attribute->value[0] encoding:NSUTF8StringEncoding];
			break;
		}
		attribute = attribute->next;
	}
	return value;
}

+ (NSString*) valueOfAttributeNamed:(NSString *)aName forElement:(VKSXMLElement*)aXMLElement error:(NSError **)error {
    // check for nil element
    if (nil == aXMLElement) {
        if (error) *error = [VKSXML errorWithCode:D_VKSXML_ELEMENT_IS_NIL];
        return @"";
    }
    
    // check for nil name parameter
    if (nil == aName) {
        if (error) *error = [VKSXML errorWithCode:D_VKSXML_ATTRIBUTE_NAME_IS_NIL];
        return @"";
    }
    
	const char * name = [aName cStringUsingEncoding:NSUTF8StringEncoding];
	NSString * value = nil;
    
	VKSXMLAttribute * attribute = aXMLElement->firstAttribute;
	while (attribute) {
		if (strlen(attribute->name) == strlen(name) && memcmp(attribute->name,name,strlen(name)) == 0) {
            if (attribute->value[0])
                value = [NSString stringWithCString:&attribute->value[0] encoding:NSUTF8StringEncoding];
            else
                value = @"";
            
			break;
		}
		attribute = attribute->next;
	}
    
    // check for attribute not found
    if (!value) {
        if (error) *error = [VKSXML errorWithCode:D_VKSXML_ATTRIBUTE_NOT_FOUND];
        return @"";
    }
    
	return value;
}

+ (VKSXMLElement*) childElementNamed:(NSString*)aName parentElement:(VKSXMLElement*)aParentXMLElement{
    
	VKSXMLElement * xmlElement = aParentXMLElement->firstChild;
	const char * name = [aName cStringUsingEncoding:NSUTF8StringEncoding];
	while (xmlElement) {
		if (strlen(xmlElement->name) == strlen(name) && memcmp(xmlElement->name,name,strlen(name)) == 0) {
			return xmlElement;
		}
		xmlElement = xmlElement->nextSibling;
	}
	return nil;
}

+ (VKSXMLElement*) childElementNamed:(NSString*)aName parentElement:(VKSXMLElement*)aParentXMLElement error:(NSError **)error {
    // check for nil element
    if (nil == aParentXMLElement) {
        if (error) *error = [VKSXML errorWithCode:D_VKSXML_ELEMENT_IS_NIL];
        return nil;
    }
    
    // check for nil name parameter
    if (nil == aName) {
        if (error) *error = [VKSXML errorWithCode:D_VKSXML_PARAM_NAME_IS_NIL];
        return nil;
    }
    
	VKSXMLElement * xmlElement = aParentXMLElement->firstChild;
	const char * name = [aName cStringUsingEncoding:NSUTF8StringEncoding];
	while (xmlElement) {
		if (strlen(xmlElement->name) == strlen(name) && memcmp(xmlElement->name,name,strlen(name)) == 0) {
			return xmlElement;
		}
		xmlElement = xmlElement->nextSibling;
	}
    
    if (error) *error = [VKSXML errorWithCode:D_VKSXML_ELEMENT_NOT_FOUND];
    
	return nil;
}

+ (VKSXMLElement*) nextSiblingNamed:(NSString*)aName searchFromElement:(VKSXMLElement*)aXMLElement{
	VKSXMLElement * xmlElement = aXMLElement->nextSibling;
	const char * name = [aName cStringUsingEncoding:NSUTF8StringEncoding];
	while (xmlElement) {
		if (strlen(xmlElement->name) == strlen(name) && memcmp(xmlElement->name,name,strlen(name)) == 0) {
			return xmlElement;
		}
		xmlElement = xmlElement->nextSibling;
	}
	return nil;
}

+ (VKSXMLElement*) nextSiblingNamed:(NSString*)aName searchFromElement:(VKSXMLElement*)aXMLElement error:(NSError **)error {
    // check for nil element
    if (nil == aXMLElement) {
        if (error) *error = [VKSXML errorWithCode:D_VKSXML_ELEMENT_IS_NIL];
        return nil;
    }
    
    // check for nil name parameter
    if (nil == aName) {
        if (error) *error = [VKSXML errorWithCode:D_VKSXML_PARAM_NAME_IS_NIL];
        return nil;
    }
    
	VKSXMLElement * xmlElement = aXMLElement->nextSibling;
	const char * name = [aName cStringUsingEncoding:NSUTF8StringEncoding];
	while (xmlElement) {
		if (strlen(xmlElement->name) == strlen(name) && memcmp(xmlElement->name,name,strlen(name)) == 0) {
			return xmlElement;
		}
		xmlElement = xmlElement->nextSibling;
	}
    
    if (error) *error = [VKSXML errorWithCode:D_VKSXML_ELEMENT_NOT_FOUND];
    
	return nil;
}

+ (void)iterateElementsForQuery:(NSString *)query fromElement:(VKSXMLElement *)anElement withBlock:(VKSXMLIterateBlock)iterateBlock {
    
    NSArray *components = [query componentsSeparatedByString:@"."];
    VKSXMLElement *currVKSXMLElement = anElement;
    
    // navigate down
    for (NSInteger i=0; i < components.count; ++i) {
        NSString *iTagName = [components objectAtIndex:i];
        
        if ([iTagName isEqualToString:@"*"]) {
            currVKSXMLElement = currVKSXMLElement->firstChild;
            
            // different behavior depending on if this is the end of the query or midstream
            if (i < (components.count - 1)) {
                // midstream
                do {
                    NSString *restOfQuery = [[components subarrayWithRange:NSMakeRange(i + 1, components.count - i - 1)] componentsJoinedByString:@"."];
                    [VKSXML iterateElementsForQuery:restOfQuery fromElement:currVKSXMLElement withBlock:iterateBlock];
                } while ((currVKSXMLElement = currVKSXMLElement->nextSibling));
                
            }
        } else {
            currVKSXMLElement = [VKSXML childElementNamed:iTagName parentElement:currVKSXMLElement];            
        }
        
        if (!currVKSXMLElement) {
            break;
        }
    }
    
    if (currVKSXMLElement) {
        // enumerate
        NSString *childTagName = [components lastObject];
        
        if ([childTagName isEqualToString:@"*"]) {
            childTagName = nil;
        }
        
        do {
            iterateBlock(currVKSXMLElement);
        } while (childTagName ? (currVKSXMLElement = [VKSXML nextSiblingNamed:childTagName searchFromElement:currVKSXMLElement]) : (currVKSXMLElement = currVKSXMLElement->nextSibling));
    }
}

+ (void)iterateAttributesOfElement:(VKSXMLElement *)anElement withBlock:(VKSXMLIterateAttributeBlock)iterateAttributeBlock {

    // Obtain first attribute from element
    VKSXMLAttribute * attribute = anElement->firstAttribute;
    
    // if attribute is valid
    
    while (attribute) {
        // Call the iterateAttributeBlock with the attribute, it's name and value
        iterateAttributeBlock(attribute, [VKSXML attributeName:attribute], [VKSXML attributeValue:attribute]);
        
        // Obtain the next attribute
        attribute = attribute->next;
    }
}

@end


// ================================================================================================
// Private Implementation
// ================================================================================================

#pragma mark -
#pragma mark Private implementation

@implementation VKSXML (Private)

+ (NSString *) errorTextForCode:(int)code {
    NSString * codeText = @"";
    
    switch (code) {
        case D_VKSXML_DATA_NIL:                  codeText = @"Data is nil";                          break;
        case D_VKSXML_DECODE_FAILURE:            codeText = @"Decode failure";                       break;
        case D_VKSXML_MEMORY_ALLOC_FAILURE:      codeText = @"Unable to allocate memory";            break;
        case D_VKSXML_FILE_NOT_FOUND_IN_BUNDLE:  codeText = @"File not found in bundle";             break;
            
        case D_VKSXML_ELEMENT_IS_NIL:            codeText = @"Element is nil";                       break;
        case D_VKSXML_ELEMENT_NAME_IS_NIL:       codeText = @"Element name is nil";                  break;
        case D_VKSXML_ATTRIBUTE_IS_NIL:          codeText = @"Attribute is nil";                     break;
        case D_VKSXML_ATTRIBUTE_NAME_IS_NIL:     codeText = @"Attribute name is nil";                break;
        case D_VKSXML_ELEMENT_TEXT_IS_NIL:       codeText = @"Element text is nil";                  break;
        case D_VKSXML_PARAM_NAME_IS_NIL:         codeText = @"Parameter name is nil";                break;
        case D_VKSXML_ATTRIBUTE_NOT_FOUND:       codeText = @"Attribute not found";                  break;
        case D_VKSXML_ELEMENT_NOT_FOUND:         codeText = @"Element not found";                    break;
            
        default: codeText = @"No Error Description!"; break;
    }
    
    return codeText;
}

+ (NSError *) errorWithCode:(int)code {
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[VKSXML errorTextForCode:code], NSLocalizedDescriptionKey, nil];
    
    return [NSError errorWithDomain:D_VKSXML_DOMAIN 
                               code:code 
                           userInfo:userInfo];
}

+ (NSError *) errorWithCode:(int)code userInfo:(NSMutableDictionary *)someUserInfo {
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:someUserInfo];
    [userInfo setValue:[VKSXML errorTextForCode:code] forKey:NSLocalizedDescriptionKey];
    
    return [NSError errorWithDomain:D_VKSXML_DOMAIN 
                               code:code 
                           userInfo:userInfo];
}

- (int) allocateBytesOfLength:(long)length error:(NSError **)error {
    bytesLength = length;
    
    NSError *localError = nil;
    
    if(!length) {
        localError = [VKSXML errorWithCode:D_VKSXML_DATA_NIL];
    }
    
	bytes = malloc(bytesLength+1);
    
    if(!bytes) {
        localError = [VKSXML errorWithCode:D_VKSXML_MEMORY_ALLOC_FAILURE];
    }
    
    if (error) *error = localError;
        
    return localError == nil ? D_VKSXML_SUCCESS : (int)[localError code];
}

- (void) decodeBytes {
	
	// -----------------------------------------------------------------------------
	// Process xml
	// -----------------------------------------------------------------------------
	
	// set elementStart pointer to the start of our xml
	char * elementStart=bytes;
	
	// set parent element to nil
	VKSXMLElement * parentXMLElement = nil;
	
	// find next element start
	while ((elementStart = strstr(elementStart,"<"))) {
		
		// detect comment section
		if (strncmp(elementStart,"<!--",4) == 0) {
			elementStart = strstr(elementStart,"-->") + 3;
			continue;
		}

		// detect cdata section within element text
		int isCDATA = strncmp(elementStart,"<![CDATA[",9);
		
		// if cdata section found, skip data within cdata section and remove cdata tags
		if (isCDATA==0) {
			
			// find end of cdata section
			char * CDATAEnd = strstr(elementStart,"]]>");
			
			// find start of next element skipping any cdata sections within text
			char * elementEnd = CDATAEnd;
			
			// find next open tag
			elementEnd = strstr(elementEnd,"<");
			// if open tag is a cdata section
			while (strncmp(elementEnd,"<![CDATA[",9) == 0) {
				// find end of cdata section
				elementEnd = strstr(elementEnd,"]]>");
				// find next open tag
				elementEnd = strstr(elementEnd,"<");
			}
			
			// calculate length of cdata content
			long CDATALength = CDATAEnd-elementStart;
			
			// calculate total length of text
			long textLength = elementEnd-elementStart;
			
			// remove begining cdata section tag
			memcpy(elementStart, elementStart+9, CDATAEnd-elementStart-9);

			// remove ending cdata section tag
			memcpy(CDATAEnd-9, CDATAEnd+3, textLength-CDATALength-3);
			
			// blank out end of text
			memset(elementStart+textLength-12,' ',12);
			
			// set new search start position 
			elementStart = CDATAEnd-9;
			continue;
		}
		
		
		// find element end, skipping any cdata sections within attributes
		char * elementEnd = elementStart+1;		
		while ((elementEnd = strpbrk(elementEnd, "<>"))) {
			if (strncmp(elementEnd,"<![CDATA[",9) == 0) {
				elementEnd = strstr(elementEnd,"]]>")+3;
			} else {
				break;
			}
		}
		
        if (!elementEnd) break;
		
		// null terminate element end
		if (elementEnd) *elementEnd = 0;
		
		// null terminate element start so previous element text doesnt overrun
		*elementStart = 0;
		
		// get element name start
		char * elementNameStart = elementStart+1;
		
		// ignore tags that start with ? or ! unless cdata "<![CDATA"
		if (*elementNameStart == '?' || (*elementNameStart == '!' && isCDATA != 0)) {
			elementStart = elementEnd+1;
			continue;
		}
		
		// ignore attributes/text if this is a closing element
		if (*elementNameStart == '/') {
			elementStart = elementEnd+1;
			if (parentXMLElement) {

				if (parentXMLElement->text) {
					// trim whitespace from start of text
					while (isspace(*parentXMLElement->text)) 
						parentXMLElement->text++;
					
					// trim whitespace from end of text
					char * end = parentXMLElement->text + strlen(parentXMLElement->text)-1;
					while (end > parentXMLElement->text && isspace(*end)) 
						*end--=0;
				}
				
				parentXMLElement = parentXMLElement->parentElement;
				
				// if parent element has children clear text
				if (parentXMLElement && parentXMLElement->firstChild)
					parentXMLElement->text = 0;
				
			}
			continue;
		}
		
		
		// is this element opening and closing
		BOOL selfClosingElement = NO;
		if (*(elementEnd-1) == '/') {
			selfClosingElement = YES;
		}
		
		
		// create new xmlElement struct
		VKSXMLElement * xmlElement = [self nextAvailableElement];
		
		// set element name
		xmlElement->name = elementNameStart;
		
		// if there is a parent element
		if (parentXMLElement) {
			
			// if this is first child of parent element
			if (parentXMLElement->currentChild) {
				// set next child element in list
				parentXMLElement->currentChild->nextSibling = xmlElement;
				xmlElement->previousSibling = parentXMLElement->currentChild;
				
				parentXMLElement->currentChild = xmlElement;
				
				
			} else {
				// set first child element
				parentXMLElement->currentChild = xmlElement;
				parentXMLElement->firstChild = xmlElement;
			}
			
			xmlElement->parentElement = parentXMLElement;
		}
		
		
		// in the following xml the ">" is replaced with \0 by elementEnd. 
		// element may contain no atributes and would return nil while looking for element name end
		// <tile> 
		// find end of element name
		char * elementNameEnd = strpbrk(xmlElement->name," /\n");
		
		
		// if end was found check for attributes
		if (elementNameEnd) {
			
			// null terminate end of elemenet name
			*elementNameEnd = 0;
			
			char * chr = elementNameEnd;
			char * name = nil;
			char * value = nil;
			char * CDATAStart = nil;
			char * CDATAEnd = nil;
			VKSXMLAttribute * lastXMLAttribute = nil;
			VKSXMLAttribute * xmlAttribute = nil;
			BOOL singleQuote = NO;
			
			int mode = VKSXML_ATTRIBUTE_NAME_START;
			
			// loop through all characters within element
			while (chr++ < elementEnd) {
				
				switch (mode) {
					// look for start of attribute name
					case VKSXML_ATTRIBUTE_NAME_START:
						if (isspace(*chr)) continue;
						name = chr;
						mode = VKSXML_ATTRIBUTE_NAME_END;
						break;
					// look for end of attribute name
					case VKSXML_ATTRIBUTE_NAME_END:
						if (isspace(*chr) || *chr == '=') {
							*chr = 0;
							mode = VKSXML_ATTRIBUTE_VALUE_START;
						}
						break;
					// look for start of attribute value
					case VKSXML_ATTRIBUTE_VALUE_START:
						if (isspace(*chr)) continue;
						if (*chr == '"' || *chr == '\'') {
							value = chr+1;
							mode = VKSXML_ATTRIBUTE_VALUE_END;
							if (*chr == '\'') 
								singleQuote = YES;
							else
								singleQuote = NO;
						}
						break;
					// look for end of attribute value
					case VKSXML_ATTRIBUTE_VALUE_END:
						if (*chr == '<' && strncmp(chr, "<![CDATA[", 9) == 0) {
							mode = VKSXML_ATTRIBUTE_CDATA_END;
						}else if ((*chr == '"' && singleQuote == NO) || (*chr == '\'' && singleQuote == YES)) {
							*chr = 0;
							
							// remove cdata section tags
							while ((CDATAStart = strstr(value, "<![CDATA["))) {
								
								// remove begin cdata tag
								memcpy(CDATAStart, CDATAStart+9, strlen(CDATAStart)-8);
								
								// search for end cdata
								CDATAEnd = strstr(CDATAStart,"]]>");
								
								// remove end cdata tag
								memcpy(CDATAEnd, CDATAEnd+3, strlen(CDATAEnd)-2);
							}
							
							
							// create new attribute
							xmlAttribute = [self nextAvailableAttribute];
							
							// if this is the first attribute found, set pointer to this attribute on element
							if (!xmlElement->firstAttribute) xmlElement->firstAttribute = xmlAttribute;
							// if previous attribute found, link this attribute to previous one
							if (lastXMLAttribute) lastXMLAttribute->next = xmlAttribute;
							// set last attribute to this attribute
							lastXMLAttribute = xmlAttribute;

							// set attribute name & value
							xmlAttribute->name = name;
							xmlAttribute->value = value;
							
							// clear name and value pointers
							name = nil;
							value = nil;
							
							// start looking for next attribute
							mode = VKSXML_ATTRIBUTE_NAME_START;
						}
						break;
						// look for end of cdata
					case VKSXML_ATTRIBUTE_CDATA_END:
						if (*chr == ']') {
							if (strncmp(chr, "]]>", 3) == 0) {
								mode = VKSXML_ATTRIBUTE_VALUE_END;
							}
						}
						break;						
					default:
						break;
				}
			}
		}
		
		// if tag is not self closing, set parent to current element
		if (!selfClosingElement) {
			// set text on element to element end+1
			if (*(elementEnd+1) != '>')
				xmlElement->text = elementEnd+1;
			
			parentXMLElement = xmlElement;
		}
		
		// start looking for next element after end of current element
		elementStart = elementEnd+1;
	}
}

// Deallocate used memory
- (void) dealloc {
    
	if (bytes) {
		free(bytes);
		bytes = nil;
	}
	
	while (currentElementBuffer) {
		if (currentElementBuffer->elements)
			free(currentElementBuffer->elements);
		
		if (currentElementBuffer->previous) {
			currentElementBuffer = currentElementBuffer->previous;
			free(currentElementBuffer->next);
		} else {
			free(currentElementBuffer);
			currentElementBuffer = 0;
		}
	}
	
	while (currentAttributeBuffer) {
		if (currentAttributeBuffer->attributes)
			free(currentAttributeBuffer->attributes);
		
		if (currentAttributeBuffer->previous) {
			currentAttributeBuffer = currentAttributeBuffer->previous;
			free(currentAttributeBuffer->next);
		} else {
			free(currentAttributeBuffer);
			currentAttributeBuffer = 0;
		}
	}

    SAFE_ARC_SUPER_DEALLOC();
//#ifndef ARC_ENABLED
//    [super dealloc];
//#endif
}

- (VKSXMLElement*) nextAvailableElement {
	currentElement++;
	
	if (!currentElementBuffer) {
		currentElementBuffer = calloc(1, sizeof(VKSXMLElementBuffer));
		currentElementBuffer->elements = (VKSXMLElement*)calloc(1,sizeof(VKSXMLElement)*MAX_ELEMENTS);
		currentElement = 0;
		rootXMLElement = &currentElementBuffer->elements[currentElement];
	} else if (currentElement >= MAX_ELEMENTS) {
		currentElementBuffer->next = calloc(1, sizeof(VKSXMLElementBuffer));
		currentElementBuffer->next->previous = currentElementBuffer;
		currentElementBuffer = currentElementBuffer->next;
		currentElementBuffer->elements = (VKSXMLElement*)calloc(1,sizeof(VKSXMLElement)*MAX_ELEMENTS);
		currentElement = 0;
	}
	
	return &currentElementBuffer->elements[currentElement];
}

- (VKSXMLAttribute*) nextAvailableAttribute {
	currentAttribute++;
	
	if (!currentAttributeBuffer) {
		currentAttributeBuffer = calloc(1, sizeof(VKSXMLAttributeBuffer));
		currentAttributeBuffer->attributes = (VKSXMLAttribute*)calloc(MAX_ATTRIBUTES,sizeof(VKSXMLAttribute));
		currentAttribute = 0;
	} else if (currentAttribute >= MAX_ATTRIBUTES) {
		currentAttributeBuffer->next = calloc(1, sizeof(VKSXMLAttributeBuffer));
		currentAttributeBuffer->next->previous = currentAttributeBuffer;
		currentAttributeBuffer = currentAttributeBuffer->next;
		currentAttributeBuffer->attributes = (VKSXMLAttribute*)calloc(MAX_ATTRIBUTES,sizeof(VKSXMLAttribute));
		currentAttribute = 0;
	}
	
	return &currentAttributeBuffer->attributes[currentAttribute];
}

@end


@implementation NSMutableURLRequest (VKSXML_HTTP)


+ (NSMutableURLRequest*) VKSXMLGetRequestWithURL:(NSURL*)url {
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:url];
    //option Since "GET" is the default
	[request setHTTPMethod:@"GET"];
    
 

 return  SAFE_ARC_AUTORELEASE(request);
    
//#ifndef ARC_ENABLED
//    return [request autorelease];
//#else
//    return request;
//#endif
    
}

+ (NSMutableURLRequest*) VKSXMLPostRequestWithURL:(NSURL*)url parameters:(NSDictionary*)parameters {
	
	NSMutableArray * params = [NSMutableArray new];
	
	for (NSString * key in [parameters allKeys]) {
		[params addObject:[NSString stringWithFormat:@"%@=%@", key, [parameters objectForKey:key]]];
	}
	
	NSData * postData = [[params componentsJoinedByString:@"&"] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:url];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setHTTPBody:postData];
    
    SAFE_ARC_RELEASE(params);
   return SAFE_ARC_AUTORELEASE(request);
    
    
//#ifndef ARC_ENABLED
//    [params release];
//    return [request autorelease];
//#else
//    return request;
//#endif
}



+ (NSMutableURLRequest*) VKSXMLSoapPostRequestWithURL:(NSURL*)url parameters:(NSMutableDictionary*)strSoapParams FunctionName :(NSString*)strFunctionName
{
   
    NSMutableArray * params = [NSMutableArray new];
	
	for (NSString * key in [strSoapParams allKeys]) {
		[params addObject:[NSString stringWithFormat:@"<%@>%@</%@>", key,[strSoapParams objectForKey:key],key]];
	}
	
    NSString *strCombinedParams = [params componentsJoinedByString:@"\n"];
    
    
    //**This is sample strSOAPAction Message need to changed as required
    NSString *strSOAPAction=[NSString stringWithFormat:@"http://www.w3schools.com/webservices/%@",strFunctionName] ;
    
    //**This is sample Soap Message need to changed as required
    NSString *soapMessage =[NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                            "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n"
                            /*"<soap:Header>\n"
                            "<AuthSoapHd xmlns=\"http://tempuri.org/\">\n"
                            "<strUserName>tarak</strUserName>\n"
                            "<strPassword>tarak$$123</strPassword>\n"
                            "</AuthSoapHd>\n"
                            "</soap:Header>\n"*/
                            "<soap:Body>\n"
                            "<%@ xmlns=\"http://www.w3schools.com/webservices/\">\n"
                            "%@\n"
                            "</%@>\n"
                            "</soap:Body>\n"
                            "</soap:Envelope>\n",strFunctionName,strCombinedParams,strFunctionName];
//    NSLog(@"%@",soapMessage);

    //can also use certain times [strSoapMessage dataUsingEncoding:NSUTF8StringEncoding]
	NSData * postData = [soapMessage dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];

 	NSMutableURLRequest *webRequest=[NSMutableURLRequest requestWithURL:url
                                                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                        timeoutInterval:60.0];
    
	NSString *msgLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
	[webRequest addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [webRequest addValue: strSOAPAction forHTTPHeaderField:@"SOAPAction"];
	[webRequest addValue:msgLength forHTTPHeaderField:@"Content-Length"];
	[webRequest setHTTPMethod:@"POST"];
	[webRequest setHTTPBody:postData];
    
    SAFE_ARC_RELEASE(strSoapMessage);
    return SAFE_ARC_AUTORELEASE(webRequest);
    
//#ifndef ARC_ENABLED
//    [strSoapMessage release];
//    return [webRequest autorelease];
//#else
//    return webRequest;
//#endif
}


@end


@implementation NSURLConnection (VKSXML_HTTP)

+ (void)VKSXMLAsyncRequest:(NSURLRequest *)request success:(VKSXMLAsyncRequestSuccessBlock)successBlock failure:(VKSXMLAsyncRequestFailureBlock)failureBlock {
    
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
		@autoreleasepool {
			NSURLResponse *response = nil;
			NSError *error = nil;
			NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
			if (error) {
				failureBlock(data,error);
			} else {
				successBlock(data,response);
			}
		}
	});
}

@end


@implementation VKSXML (VKSXML_HTTP)

//Factory Methods
+ (id)newVKSXMLWithURL:(NSURL*)aURL success:(VKSXMLSuccessBlock)successBlock failure:(VKSXMLFailureBlock)failureBlock {
	return [[VKSXML alloc] initWithURL_GetRequest:aURL success:successBlock failure:failureBlock];
}
+ (id)newVKSXMLWithURL_PostRequest:(NSURL*)aURL parameters:(NSDictionary*)parameters success:(VKSXMLSuccessBlock)successBlock failure:(VKSXMLFailureBlock)failureBlock
{
    return [[VKSXML alloc]initWithURL_PostRequest:aURL parameters:parameters success:successBlock failure:failureBlock];
}
+ (id)newVKSXMLWithURL_SoapRequest:(NSURL*)aURL parameters:(NSMutableDictionary*)strSoapMessage FunctionName:(NSString*)strFunctionName success:(VKSXMLSuccessBlock)successBlock failure:(VKSXMLFailureBlock)failureBlock
{
	return [[VKSXML alloc] initWithURL_SoapRequest:aURL parameters:strSoapMessage FunctionName:strFunctionName success:successBlock failure:failureBlock];
}

//instance Methods
- (id)initWithURL_GetRequest:(NSURL*)aURL success:(VKSXMLSuccessBlock)successBlock failure:(VKSXMLFailureBlock)failureBlock {
	self = [self init];
	if (self != nil) {
        
        VKSXMLAsyncRequestSuccessBlock requestSuccessBlock = ^(NSData *data, NSURLResponse *response) {
            
            NSError *error = nil;
            [self decodeData:data withError:&error];
            
            // If VKSXML found a root node, process element and iterate all children
            if (!error) {
                successBlock(self);
            } else {
                failureBlock(self, error);
            }
        };
        
        VKSXMLAsyncRequestFailureBlock requestFailureBlock = ^(NSData *data, NSError *error) {
            failureBlock(self, error);
        };
        
        
        [NSURLConnection VKSXMLAsyncRequest:[NSMutableURLRequest VKSXMLGetRequestWithURL:aURL]
                                    success:requestSuccessBlock
                                    failure:requestFailureBlock];
	}
	return self;
}

- (id)initWithURL_PostRequest:(NSURL*)aURL parameters:(NSDictionary*)parameters success:(VKSXMLSuccessBlock)successBlock failure:(VKSXMLFailureBlock)failureBlock
{
	self = [self init];
	if (self != nil) {
        
        VKSXMLAsyncRequestSuccessBlock requestSuccessBlock = ^(NSData *data, NSURLResponse *response) {
            
            NSError *error = nil;
            [self decodeData:data withError:&error];
            
            // If VKSXML found a root node, process element and iterate all children
            if (!error) {
                successBlock(self);
            } else {
                failureBlock(self, error);
            }
        };
        
        VKSXMLAsyncRequestFailureBlock requestFailureBlock = ^(NSData *data, NSError *error) {
            failureBlock(self, error);
        };
        
        
        [NSURLConnection VKSXMLAsyncRequest:[NSMutableURLRequest VKSXMLPostRequestWithURL:aURL parameters:parameters]
                                    success:requestSuccessBlock
                                    failure:requestFailureBlock];
	}
	return self;
}

- (id)initWithURL_SoapRequest:(NSURL*)aURL parameters:(NSMutableDictionary*)strSoapMessage FunctionName:(NSString*)strFunctionName success:(VKSXMLSuccessBlock)successBlock failure:(VKSXMLFailureBlock)failureBlock;
{
	self = [self init];
	if (self != nil) {
        
        VKSXMLAsyncRequestSuccessBlock requestSuccessBlock = ^(NSData *data, NSURLResponse *response) {
            
            NSError *error = nil;
            [self decodeData:data withError:&error];
            
            // If VKSXML found a root node, process element and iterate all children
            if (!error) {
                successBlock(self);
            } else {
                failureBlock(self, error);
            }
        };
        
        VKSXMLAsyncRequestFailureBlock requestFailureBlock = ^(NSData *data, NSError *error) {
            failureBlock(self, error);
        };
        
//        + (NSMutableURLRequest*) VKSXMLSoapPostRequestWithURL:(NSURL*)url parameters:(NSString*)strSoapParams :(NSString*)strFunctionName
  

        
        [NSURLConnection VKSXMLAsyncRequest:[NSMutableURLRequest VKSXMLSoapPostRequestWithURL:aURL parameters:strSoapMessage FunctionName:strFunctionName]
                                    success:requestSuccessBlock
                                    failure:requestFailureBlock];
	}
	return self;
}
@end



@implementation VKSXML (VKSXML_NSDictionary)
+ (NSDictionary*)dictionaryWithXMLNode:(VKSXMLElement*)element
{
    NSMutableDictionary *elementDict = [[NSMutableDictionary alloc] init];
    
    VKSXMLAttribute *attribute = element->firstAttribute;
    while (attribute) {
        [elementDict setObject:[VKSXML attributeValue:attribute] forKey:[VKSXML attributeName:attribute]];
        attribute = attribute->next;
    }
    
    VKSXMLElement *childElement = element->firstChild;
    if (childElement) {
        
        while (childElement) {
            
            if ([elementDict objectForKey:[VKSXML elementName:childElement]] == nil) {
                
                [elementDict addEntriesFromDictionary:[self dictionaryWithXMLNode:childElement]];
                
            } else if ([[elementDict objectForKey:[VKSXML elementName:childElement]] isKindOfClass:[NSArray class]]) {
                
                NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[elementDict objectForKey:[VKSXML elementName:childElement]]];
                [items addObject:[[self dictionaryWithXMLNode:childElement] objectForKey:[VKSXML elementName:childElement]]];
                [elementDict setObject:[NSArray arrayWithArray:items] forKey:[VKSXML elementName:childElement]];
                   SAFE_ARC_RELEASE(items);
//                [items release];
                items = nil;
                
            } else {
                
                NSMutableArray *items = [[NSMutableArray alloc] init];
                [items addObject:[elementDict objectForKey:[VKSXML elementName:childElement]]];
                [items addObject:[[self dictionaryWithXMLNode:childElement] objectForKey:[VKSXML elementName:childElement]]];
                [elementDict setObject:[NSArray arrayWithArray:items] forKey:[VKSXML elementName:childElement]];
                   SAFE_ARC_RELEASE(items);
//                [items release];
                items = nil;
            }
            
            childElement = childElement->nextSibling;
        }
        
    } else if ([VKSXML textForElement:element] != nil && [VKSXML textForElement:element].length>0) {
        
        if ([elementDict count]>0) {
            [elementDict setObject:[VKSXML textForElement:element] forKey:@"text"];
        } else {
            [elementDict setObject:[VKSXML textForElement:element] forKey:[VKSXML elementName:element]];
        }
    }
    
    
    NSDictionary *resultDict = nil;
    
    if ([elementDict count]>0) {
        
        if ([elementDict valueForKey:[VKSXML elementName:element]] == nil) {
            resultDict = [NSDictionary dictionaryWithObject:elementDict forKey:[VKSXML elementName:element]];
        } else {
            resultDict = [NSDictionary dictionaryWithDictionary:elementDict];
        }
    }
    
   SAFE_ARC_RELEASE(elementDict);
//    [elementDict release];
    elementDict = nil;
    
    return resultDict;
}


+ (NSDictionary*)dictionaryWithXMLData:(NSData*)data
{
    VKSXML *vkfXml = [[VKSXML alloc]initWithXMLData:data error:nil];
    if (!vkfXml.rootXMLElement) {
        return nil;
    }
    return [self dictionaryWithXMLNode:vkfXml.rootXMLElement];
}

+ (id)getDataAtPath:(NSString *)path fromResultObject:(NSDictionary *)resultObject
{
	id		dataObject	= resultObject;
	NSArray *pathArray	= [path componentsSeparatedByString:@"."];
    
	for (NSString *step in pathArray) {
		if ([dataObject isKindOfClass:[NSDictionary class]])
			dataObject = [dataObject objectForKey:step];
		else
			return nil;
	}
    
	return dataObject;
}



@end
