# Key-Value Coding（键值编码）


## 关于键值编码

键值编码（KVC）是一种由`NSKeyValueCoding`非正式协议提供的机制，对象采用该机制来提供对其属性的间接访问。当对象兼容键值编码时，可以通过字符串参数和简洁、统一的接口来访问其属性。这种间接访问机制补充了实例变量和其关联的访问器方法提供的直接访问。

通常使用访问器方法来访问对象的属性。get访问器（或者getter）返回属性的值，set访问器（或者setter）设置属性的值。在Objective-C中，还可以直接访问属性的实例变量。以任何方式访问对象属性都很简单，但需要调用属性特定的方法或者变量名称。随着属性列表的增长或改变，访问这些属性的代码也必须如此。 相反，兼容键值编码的对象提供了一个简单的消息传递接口，该接口在其所有属性中都是一致的。

键值编码是一个基本概念，是许多其他Cocoa技术的基础，例如KVO、Cocoa绑定、Core Data和AppleScript-ability。在某些情况下，键值编码还有助于简化代码。


## 键值编码基本原理

### 访问对象属性

对象通常在其接口声明中指定属性，并且这些属性属于以下几种类别之一：
- **Attributes**：这些是简单值，例如标量、字符串和或者布尔值。诸如`NSNumber`之类的值对象和诸如`NSColor`之类的其他不可变类型也被视为属性。
- **To-one relationships**：这些是具有自己属性的可变对象，对象的属性可以在对象本身不变的情况下更改。例如，一个`BankAccount`对象可能具有一个`owner`属性，该属性是`People`对象的实例，`owner`属性本身具有一个`address`属性。在`BankAccount`对象对`owner`属性的引用不变的情况下，`owner`的`address`属性可能会更改。换句话说，银行账户的所有者没有变更，但所有者的地址可能变了。
- **To-many relationships**：这些是集合对象。通常使用`NSArray`或者`NSSet`的实例来保存此类集合，也可以使用自定义集合类。

以下代码中声明的`BankAccount`对象演示了每种类型的属性之一。
```
@interface BankAccount : NSObject

@property (nonatomic) NSNumber* currentBalance;              // An attribute
@property (nonatomic) Person* owner;                         // A to-one relation
@property (nonatomic) NSArray< Transaction* >* transactions; // A to-many relation

@end
```
为了维护封装，对象通常为其接口上的属性提供访问器方法。对象的开发者可以显示地编写这些方法，也可以依赖编译器自动合成它们。无论哪种方式，使用这些访问器之一的代码的开发者必须在编译之前将属性名称写入代码中。访问器方法的名称成为使用它的代码的静态部分。例如，前面声明的`BankAccount`对象，编译器会合成一个可以给`myAccount`实例调用的setter：
```
[myAccount setCurrentBalance:@(100.0)];
```
这样虽然直接，但是缺乏灵活性。另一方面，兼容键值编码的对象提供了使用字符串标识符访问对象属性的更通用机制。


### 使用键（Key）和键路径（Key Path）标识对象的属性

键是标识特定属性的字符串。按照惯例，表示属性的键是代码中显示的属性本身的名称。键必须使用ASCII编码，不能包含空格，并且通常以小写字母开头（尽管有例外，例如在许多类中找到的URL属性）。

由于`BankAccount`类是兼容键值编码的，所以它可以识别键`owner`、`currentBalance`和`transactions`，它们是其属性的名称。可以通过键代替调用`setCurrentBalance:`方法为`currentBalance`属性设置值：
```
[myAccount setValue:@(100.0) forKey:@"currentBalance"];
```
实际上，可以使用键参数不同的相同方法设置`myAccount`对象的所有属性。因为参数是字符串，所以它是可以在运行时操作的变量。

键路径是一个使用点分割多个键的字符串，用于指定要遍历的对象属性序列。序列中第一个键的属性是相对于接收者的，并且后面的键都是相对于其前面一个键所表示的属性。键路径对于使用单个方法深入到对象层次结构是非常有用的。

例如，假设`Person`和`Address`类也兼容键值编码，那么应用于`myAccount`实例的键路径`owner.address.street`指的是存储在银行帐户所有者地址中的街道字符串的值。

### 使用键获取属性值

当对象遵循`NSKeyValueCoding`协议时，其是兼容键值编码的。继承自`NSObject`（其提供了`NSKeyValueCoding`协议的必要方法的默认实现）的对象会自动采用此协议的某些默认行为。这样的对象至少实现了以下基础的基于键的getter：
- `valueForKey:`：返回接收者的与指定键对应的属性的值。如果根据[访问器搜索模式](#turn)中描述的规则无法找到key所指定的属性，则该对象会向自身发送`valueForUndefinedKey:`消息。`valueForUndefinedKey:`方法的默认实现会抛出一个`NSUndefinedKeyException`，但是子类可以覆盖此行为并更优雅地处理该情况。
- `valueForKeyPath:`：返回相对于接收者的指定键路径对应的属性的值。键路径序列中的任一对象不能兼容特定键的键值编码——即其`valueForKey:`方法的默认实现无法找到访问器方法——该对象会接收到一个`valueForUndefinedKey:`消息。
- `dictionaryWithValuesForKeys:`：返回接收者的与键数组中每个键对应的属性的值。该方法为数组中的每个键调用`valueForKey:`方法，返回的`NSDictionary`包含数组中所有键的值。

> **注意**：集合对象（如`NSArray`，`NSDictionary`和`NSSet`）不能包含`nil`作为值。相反，可以使用`NSNull`对象来表示`nil`值，`NSNull`提供了一个实例来表示对象属性的`nil`值。`dictionaryWithValuesForKeys:`方法和相关的`setValuesForKeysWithDictionary:`方法的默认实现自动在`NSNull`（在字典参数中）和`nil`（在存储属性中）之间进行转换。

当使用键路径来寻址属性时，如果键路径中的最后一个键的前一个键是to-many relationship（即它引用一个集合），则返回的值是一个包含前一个键对应集合中的每个值的对应最后一个键的值的集合。例如，请求键路径`transactions.payee`会返回一个包含所有`Transaction`对象的`payee`实例的数组。这也适用于键路径中的多个数组。例如，键路径`accounts.transactions.payee`返回一个包含所有账户中所有交易的所有收款人对象的数组。


### 使用键设置属性值

与getter一样，兼容键值编码的对象也提供了一小组具有默认行为的通用setter：
- `setValue:forKey:`：将消息接收者的与指定键对应的属性设置为给定值。`setValue:forKey:`方法的默认实现自动解包表示标量和结构体的`NSNumber`和`NSValue`对象，并将它们分配给属性。有关包装和解包语义的详细信息，请参看[表示非对象值](#turn)。如果消息接收对象没有指定的键对应的属性，则该对象会向自身发送`setValue:forUndefinedKey:`消息。`setValue:forUndefinedKey:`方法的默认实现抛出一个`NSUndefinedKeyException`。但是，子类可以重写此方法以自定义方式处理请求。
- `setValue:forKeyPath:`：将相对于接收者的指定键路径对应的属性设置为给定值。键路径序列中的任何一个不兼容兼职编码的对象会收到`setValue:forUndefinedKey:`消息。
- `setValuesForKeysWithDictionary:`：使用字典键标识属性，使用字典中的设置属性的值。其默认实现会为每个键值对调用`setValue:forKey:`方法，并根据需要使用`nil`替换`NSNull`对象。

在默认实现中，当试图将非对象属性设置为`nil`时，兼容键值编码的对象会向自身发送`setNilValueForKey:`方法。`setNilValueForKey:`方法的默认实现抛出一个`NSInvalidArgumentException`，但是对象可能会覆盖此行为以替换默认值或标记值，如[处理非对象值](#turn)中所述。




















