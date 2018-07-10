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

key是标识特定属性的字符串。按照惯例，代表属性的key是代码中显示的属性本身的名称。key必须使用ASCII编码，可能不包含


























