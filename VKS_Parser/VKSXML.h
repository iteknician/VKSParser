
// ================================================================================================
//Created by Vikas Rajpurohit
//  VKSXML.h

#if !defined(__clang__) || __clang_major__ < 3
#ifndef __bridge
#define __bridge
#endif

#ifndef __bridge_retain
#define __bridge_retain
#endif

#ifndef __bridge_retained
#define __bridge_retained
#endif

#ifndef __autoreleasing
#define __autoreleasing
#endif

#ifndef __strong
#define __strong
#endif

#ifndef __unsafe_unretained
#define __unsafe_unretained
#endif

#ifndef __weak
#define __weak
#endif
#endif

#if __has_feature(objc_arc)
#define SAFE_ARC_PROP_RETAIN strong
#define SAFE_ARC_RETAIN(x) (x)
#define SAFE_ARC_RELEASE(x)
#define SAFE_ARC_AUTORELEASE(x) (x)
#define SAFE_ARC_BLOCK_COPY(x) (x)
#define SAFE_ARC_BLOCK_RELEASE(x)
#define SAFE_ARC_SUPER_DEALLOC()
#define SAFE_ARC_AUTORELEASE_POOL_START() @autoreleasepool {
#define SAFE_ARC_AUTORELEASE_POOL_END() }
#else
#define SAFE_ARC_PROP_RETAIN retain
#define SAFE_ARC_RETAIN(x) ([(x) retain])
#define SAFE_ARC_RELEASE(x) ([(x) release])
#define SAFE_ARC_AUTORELEASE(x) ([(x) autorelease])
#define SAFE_ARC_BLOCK_COPY(x) (Block_copy(x))
#define SAFE_ARC_BLOCK_RELEASE(x) (Block_release(x))
#define SAFE_ARC_SUPER_DEALLOC() ([super dealloc])
#define SAFE_ARC_AUTORELEASE_POOL_START() NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#define SAFE_ARC_AUTORELEASE_POOL_END() [pool release];
#endif




@class VKSXML;


// ================================================================================================
//  Error Codes
// ================================================================================================
enum VKSXMLErrorCodes {
    D_VKSXML_SUCCESS = 0,

    D_VKSXML_DATA_NIL,
    D_VKSXML_DECODE_FAILURE,
    D_VKSXML_MEMORY_ALLOC_FAILURE,
    D_VKSXML_FILE_NOT_FOUND_IN_BUNDLE,
    
    D_VKSXML_ELEMENT_IS_NIL,
    D_VKSXML_ELEMENT_NAME_IS_NIL,
    D_VKSXML_ELEMENT_NOT_FOUND,
    D_VKSXML_ELEMENT_TEXT_IS_NIL,
    D_VKSXML_ATTRIBUTE_IS_NIL,
    D_VKSXML_ATTRIBUTE_NAME_IS_NIL,
    D_VKSXML_ATTRIBUTE_NOT_FOUND,
    D_VKSXML_PARAM_NAME_IS_NIL
};


// ================================================================================================
//  Defines
// ================================================================================================
#define D_VKSXML_DOMAIN @"com.VKS.VKSXML"

#define MAX_ELEMENTS 100
#define MAX_ATTRIBUTES 100

#define VKSXML_ATTRIBUTE_NAME_START 0
#define VKSXML_ATTRIBUTE_NAME_END 1
#define VKSXML_ATTRIBUTE_VALUE_START 2
#define VKSXML_ATTRIBUTE_VALUE_END 3
#define VKSXML_ATTRIBUTE_CDATA_END 4

// ================================================================================================
//  Structures
// ================================================================================================

/** The VKSXMLAttribute structure holds information about a single XML attribute. The structure holds the attribute name, value and next sibling attribute. This structure allows us to create a linked list of attributes belonging to a specific element.
 */
typedef struct _VKSXMLAttribute {
	char * name;
	char * value;
	struct _VKSXMLAttribute * next;
} VKSXMLAttribute;



/** The VKSXMLElement structure holds information about a single XML element. The structure holds the element name & text along with pointers to the first attribute, parent element, first child element and first sibling element. Using this structure, we can create a linked list of VKSXMLElements to map out an entire XML file.
 */
typedef struct _VKSXMLElement {
	char * name;
	char * text;
	
	VKSXMLAttribute * firstAttribute;
	
	struct _VKSXMLElement * parentElement;
	
	struct _VKSXMLElement * firstChild;
	struct _VKSXMLElement * currentChild;
	
	struct _VKSXMLElement * nextSibling;
	struct _VKSXMLElement * previousSibling;
	
} VKSXMLElement;

/** The VKSXMLElementBuffer is a structure that holds a buffer of VKSXMLElements. When the buffer of elements is used, an additional buffer is created and linked to the previous one. This allows for efficient memory allocation/deallocation elements.
 */
typedef struct _VKSXMLElementBuffer {
	VKSXMLElement * elements;
	struct _VKSXMLElementBuffer * next;
	struct _VKSXMLElementBuffer * previous;
} VKSXMLElementBuffer;



/** The VKSXMLAttributeBuffer is a structure that holds a buffer of VKSXMLAttributes. When the buffer of attributes is used, an additional buffer is created and linked to the previous one. This allows for efficient memeory allocation/deallocation of attributes.
 */
typedef struct _VKSXMLAttributeBuffer {
	VKSXMLAttribute * attributes;
	struct _VKSXMLAttributeBuffer * next;
	struct _VKSXMLAttributeBuffer * previous;
} VKSXMLAttributeBuffer;


// ================================================================================================
//  Block Callbacks
// ================================================================================================
typedef void (^VKSXMLSuccessBlock)(VKSXML *VKSXML);
typedef void (^VKSXMLFailureBlock)(VKSXML *VKSXML, NSError *error);
typedef void (^VKSXMLIterateBlock)(VKSXMLElement *element);
typedef void (^VKSXMLIterateAttributeBlock)(VKSXMLAttribute *attribute, NSString *attributeName, NSString *attributeValue);


typedef void (^VKSXMLAsyncRequestSuccessBlock)(NSData *,NSURLResponse *);
typedef void (^VKSXMLAsyncRequestFailureBlock)(NSData *,NSError *);

// ================================================================================================
//  VKSXML Public Interface
// ================================================================================================

@interface VKSXML : NSObject {
	
@private
	VKSXMLElement * rootXMLElement;
	
	VKSXMLElementBuffer * currentElementBuffer;
	VKSXMLAttributeBuffer * currentAttributeBuffer;
	
	long currentElement;
	long currentAttribute;
	
	char * bytes;
	long bytesLength;
}


@property (nonatomic, readonly) VKSXMLElement * rootXMLElement;

+ (id)newVKSXMLWithXMLString:(NSString*)aXMLString error:(NSError **)error;
+ (id)newVKSXMLWithXMLData:(NSData*)aData error:(NSError **)error;
+ (id)newVKSXMLWithXMLFile:(NSString*)aXMLFile error:(NSError **)error;
+ (id)newVKSXMLWithXMLFile:(NSString*)aXMLFile fileExtension:(NSString*)aFileExtension error:(NSError **)error;

+ (id)newVKSXMLWithXMLString:(NSString*)aXMLString __attribute__((deprecated));
+ (id)newVKSXMLWithXMLData:(NSData*)aData __attribute__((deprecated));
+ (id)newVKSXMLWithXMLFile:(NSString*)aXMLFile __attribute__((deprecated));
+ (id)newVKSXMLWithXMLFile:(NSString*)aXMLFile fileExtension:(NSString*)aFileExtension __attribute__((deprecated));


- (id)initWithXMLString:(NSString*)aXMLString error:(NSError **)error;
- (id)initWithXMLData:(NSData*)aData error:(NSError **)error;
- (id)initWithXMLFile:(NSString*)aXMLFile error:(NSError **)error;
- (id)initWithXMLFile:(NSString*)aXMLFile fileExtension:(NSString*)aFileExtension error:(NSError **)error;

- (id)initWithXMLString:(NSString*)aXMLString __attribute__((deprecated));
- (id)initWithXMLData:(NSData*)aData __attribute__((deprecated));
- (id)initWithXMLFile:(NSString*)aXMLFile __attribute__((deprecated));
- (id)initWithXMLFile:(NSString*)aXMLFile fileExtension:(NSString*)aFileExtension __attribute__((deprecated));


- (int) decodeData:(NSData*)data;
- (int) decodeData:(NSData*)data withError:(NSError **)error;

@end

// ================================================================================================
//  VKSXML Static Functions Interface
// ================================================================================================

@interface VKSXML (StaticFunctions)

+ (NSString*) elementName:(VKSXMLElement*)aXMLElement;
+ (NSString*) elementName:(VKSXMLElement*)aXMLElement error:(NSError **)error;
+ (NSString*) textForElement:(VKSXMLElement*)aXMLElement;
+ (NSString*) textForElement:(VKSXMLElement*)aXMLElement error:(NSError **)error;
+ (NSString*) valueOfAttributeNamed:(NSString *)aName forElement:(VKSXMLElement*)aXMLElement;
+ (NSString*) valueOfAttributeNamed:(NSString *)aName forElement:(VKSXMLElement*)aXMLElement error:(NSError **)error;

+ (NSString*) attributeName:(VKSXMLAttribute*)aXMLAttribute;
+ (NSString*) attributeName:(VKSXMLAttribute*)aXMLAttribute error:(NSError **)error;
+ (NSString*) attributeValue:(VKSXMLAttribute*)aXMLAttribute;
+ (NSString*) attributeValue:(VKSXMLAttribute*)aXMLAttribute error:(NSError **)error;

+ (VKSXMLElement*) nextSiblingNamed:(NSString*)aName searchFromElement:(VKSXMLElement*)aXMLElement;
+ (VKSXMLElement*) childElementNamed:(NSString*)aName parentElement:(VKSXMLElement*)aParentXMLElement;

+ (VKSXMLElement*) nextSiblingNamed:(NSString*)aName searchFromElement:(VKSXMLElement*)aXMLElement error:(NSError **)error;
+ (VKSXMLElement*) childElementNamed:(NSString*)aName parentElement:(VKSXMLElement*)aParentXMLElement error:(NSError **)error;

+ (void)iterateElementsForQuery:(NSString *)query fromElement:(VKSXMLElement *)anElement withBlock:(VKSXMLIterateBlock)iterateBlock;
+ (void)iterateAttributesOfElement:(VKSXMLElement *)anElement withBlock:(VKSXMLIterateAttributeBlock)iterateBlock;


@end


@interface NSMutableURLRequest (VKSXML_HTTP)

+ (NSMutableURLRequest*) VKSXMLGetRequestWithURL:(NSURL*)url;
+ (NSMutableURLRequest*) VKSXMLPostRequestWithURL:(NSURL*)url parameters:(NSDictionary*)parameters;
+ (NSMutableURLRequest*) VKSXMLSoapPostRequestWithURL:(NSURL*)url parameters:(NSMutableDictionary*)strSoapParams FunctionName :(NSString*)strFunctionName;

@end


@interface NSURLConnection (VKSXML_HTTP)

+ (void)VKSXMLAsyncRequest:(NSURLRequest *)request success:(VKSXMLAsyncRequestSuccessBlock)successBlock failure:(VKSXMLAsyncRequestFailureBlock)failureBlock;

@end


@interface VKSXML (VKSXML_HTTP)

+ (id)newVKSXMLWithURL:(NSURL*)aURL success:(VKSXMLSuccessBlock)successBlock failure:(VKSXMLFailureBlock)failureBlock;
+ (id)newVKSXMLWithURL_PostRequest:(NSURL*)aURL parameters:(NSDictionary*)parameters success:(VKSXMLSuccessBlock)successBlock failure:(VKSXMLFailureBlock)failureBlock;
+ (id)newVKSXMLWithURL_SoapRequest:(NSURL*)aURL parameters:(NSMutableDictionary*)strSoapMessage FunctionName:(NSString*)strFunctionName success:(VKSXMLSuccessBlock)successBlock failure:(VKSXMLFailureBlock)failureBlock;


- (id)initWithURL_GetRequest:(NSURL*)aURL success:(VKSXMLSuccessBlock)successBlock failure:(VKSXMLFailureBlock)failureBlock;
- (id)initWithURL_PostRequest:(NSURL*)aURL parameters:(NSDictionary*)parameters success:(VKSXMLSuccessBlock)successBlock failure:(VKSXMLFailureBlock)failureBlock;
- (id)initWithURL_SoapRequest:(NSURL*)aURL parameters:(NSMutableDictionary*)strSoapMessage FunctionName:(NSString*)strFunctionName success:(VKSXMLSuccessBlock)successBlock failure:(VKSXMLFailureBlock)failureBlock;


@end


@interface VKSXML (VKSXML_NSDictionary)
+ (NSDictionary*)dictionaryWithXMLNode:(VKSXMLElement*)element;
+ (NSDictionary*)dictionaryWithXMLData:(NSData*)data;
+ (id)getDataAtPath:(NSString *)path fromResultObject:(NSDictionary *)resultObject;
@end

