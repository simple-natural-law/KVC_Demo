# KVC键值编码（Key-Value Coding）


## 关于键值编码

键值编码（KVC）是一种由`NSKeyValueCoding`非正式协议提供的机制，对象采用该机制来提供对其属性的间接访问。当对象兼容键值编码时，可以使用简洁、统一的接口和字符串参数来访问其属性。这种间接访问机制补充了实例变量和其关联的访问器方法提供的直接访问。

通常情况下，使用访问器方法来访问对象的属性。get访问器（或者getter）返回属性的值，set访问器（或者setter）设置属性的值。在Objective-C中，还可以直接访问属性的实例变量。以任何方式访问对象属性都很简单，但需要调用属性特定的方法或者变量名称。随着属性列表的增长或改变，访问这些属性的代码也必须如此。 相反，兼容键值编码的对象提供了一个简单的消息传递接口，该接口在其所有属性中都是一致的。

键值编码是一个基本概念，是许多其他Cocoa技术的基础，例如KVO、Cocoa绑定、Core Data和AppleScript-ability。在某些情况下，键值编码还有助于简化代码。


## 访问对象属性

对象通常在其接口声明中指定属性，并且这些属性属于以下几种类别之一：
- **Attributes**：这些是简单值，例如标量、字符串和或者布尔值。诸如`NSNumber`之类的值对象和诸如`NSColor`之类的其他不可变类型也被视为属性。
- **To-one relationships**：这些是具有自己属性的可变对象，对象的属性可以在对象本身不变的情况下更改。例如，一个`BankAccount`对象可能具有一个`owner`属性，该属性是`People`对象的实例，`owner`属性本身具有一个`address`属性。在`BankAccount`对象对`owner`属性的引用不变的情况下，`owner`的`address`属性可能会更改。换句话说，银行账户的所有者没有变更，但所有者的地址可能变了。
- **To-many relationships**：这些是集合对象。通常是`NSArray`或者`NSSet`的实例，也可以是自定义集合类。

以下代码中声明的`BankAccount`对象演示了每种类型的属性之一。
```
@interface BankAccount : NSObject

@property (nonatomic) NSNumber* currentBalance;              // An attribute
@property (nonatomic) Person* owner;                         // A to-one relation
@property (nonatomic) NSArray< Transaction* >* transactions; // A to-many relation

@end
```
为了保持封装性，对象通常为其接口上的属性提供访问器方法。可以显式地编写这些方法，也可以依赖编译器自动合成它们。无论哪种方式，必须在编译之前将属性名称写入代码中。例如，前面声明的`BankAccount`对象，编译器会合成一个可以给`myAccount`实例调用的setter：
```
[myAccount setCurrentBalance:@(100.0)];
```
这样虽然直接，但是缺乏灵活性。另一方面，兼容键值编码的对象提供了使用字符串标识符访问对象属性的更通用机制。


### 使用键（Key）和键路径（Key Path）标识对象的属性

键是标识特定属性的字符串。按照惯例，表示属性的键是代码中显示的属性本身的名称。键必须使用ASCII编码，不能包含空格，并且通常以小写字母开头。

由于`BankAccount`类是兼容键值编码的，所以它可以识别键`owner`、`currentBalance`和`transactions`，它们是其属性的名称。可以通过键代替调用`setCurrentBalance:`方法为`currentBalance`属性设置值：
```
[myAccount setValue:@(100.0) forKey:@"currentBalance"];
```
实际上，可以使用键参数不同的相同方法设置`myAccount`对象的所有属性。因为参数是字符串，所以它是可以在运行时操作的变量。

键路径是一个使用点分割多个键的字符串，用于指定要遍历的对象属性序列。序列中第一个键的属性是相对于接收者的，并且后面的键都是相对于其前面一个键所表示的属性。键路径对于使用单个方法深入到对象层次结构是非常有用的。

例如，假设`Person`和`Address`类也兼容键值编码，那么应用于`myAccount`实例的键路径`owner.address.street`指的是存储在银行帐户所有者地址中的街道字符串的值。

### 使用键获取属性值

当对象遵循`NSKeyValueCoding`协议时，其是兼容键值编码的。继承自`NSObject`（其提供了`NSKeyValueCoding`协议的必要方法的默认实现）的对象会自动采用此协议的某些默认行为。这样的对象至少实现了以下基础的基于键的getter：
- `valueForKey:`：返回接收者的与指定键对应的属性的值。如果根据[访问器查找方式](#turn)中描述的规则无法找到key所指定的属性，则该对象会向自身发送`valueForUndefinedKey:`消息。`valueForUndefinedKey:`方法的默认实现会抛出一个`NSUndefinedKeyException`，但是子类可以覆盖此行为并更优雅地处理该情况。
- `valueForKeyPath:`：返回相对于接收者的指定键路径对应的属性的值。键路径序列中的任一对象不能兼容特定键的键值编码——即其`valueForKey:`方法的默认实现无法找到访问器方法——该对象会接收到一个`valueForUndefinedKey:`消息。
- `dictionaryWithValuesForKeys:`：返回接收者的与键数组中每个键对应的属性的值。该方法为数组中的每个键调用`valueForKey:`方法，返回的`NSDictionary`包含数组中所有键的值。

> **注意**：集合对象（如`NSArray`，`NSDictionary`和`NSSet`）不能包含`nil`作为值。相反，可以使用`NSNull`对象来表示`nil`值，`NSNull`提供了一个实例来表示对象属性的`nil`值。`dictionaryWithValuesForKeys:`方法和相关的`setValuesForKeysWithDictionary:`方法的默认实现自动在`NSNull`（在字典参数中）和`nil`（在存储属性中）之间进行转换。

当使用键路径来寻址属性时，如果键路径中的最后一个键的前一个键是to-many relationship（即它引用一个集合），则返回的值是一个包含集合中的每个对象的最后一个键所标识属性的值的集合。例如，请求键路径`transactions.payee`会返回一个包含所有`Transaction`对象的`payee`实例的数组。这也适用于键路径中的多个数组。例如，键路径`accounts.transactions.payee`返回一个包含所有账户中所有交易的所有收款人对象的数组。


### 使用键设置属性值

与getter一样，兼容键值编码的对象也提供了一组具有默认行为的通用setter：
- `setValue:forKey:`：将消息接收者的与指定键对应的属性设置为给定值。`setValue:forKey:`方法的默认实现自动解包表示标量和结构体的`NSNumber`和`NSValue`对象，并将它们分配给属性。有关包装和解包语义的详细信息，请参看[表示非对象值](#turn)。如果消息接收对象没有指定的键对应的属性，则该对象会向自身发送`setValue:forUndefinedKey:`消息。`setValue:forUndefinedKey:`方法的默认实现抛出一个`NSUndefinedKeyException`。但是，子类可以重写此方法以自定义方式处理请求。
- `setValue:forKeyPath:`：将相对于接收者的指定键路径对应的属性设置为给定值。键路径序列中的任何一个不兼容键值编码的对象会收到`setValue:forUndefinedKey:`消息。
- `setValuesForKeysWithDictionary:`：使用字典键标识属性，使用字典中的设置属性的值。其默认实现会为每个键值对调用`setValue:forKey:`方法，并根据需要使用`nil`替换`NSNull`对象。

在默认实现中，当试图将非对象属性设置为`nil`时，兼容键值编码的对象会向自身发送`setNilValueForKey:`方法。`setNilValueForKey:`方法的默认实现抛出一个`NSInvalidArgumentException`，但是对象可以覆盖此行为以替换默认值或标记值，如[处理非对象值](#turn)中所述。


### 使用键简化对象访问

要了解基于键的getter和setter如何简化代码，请考虑以下示例。 在macOS中，`NSTableView`和`NSOutlineView`对象将标识符字符串与其每个列相关联。 如果支持表的模型对象不兼容键值编码，则表的数据源方法将被强制检查每个列标识符来查找要返回的正确属性，如下面代码所示。 此外，当未来向模型添加另一个属性（在本例中`Person`对象）时，还必须重新访问数据源方法，添加另一个条件来测试新属性并返回相关值。
```
- (id)tableView:(NSTableView *)tableview objectValueForTableColumn:(id)column row:(NSInteger)row
{
    id result = nil;
    Person *person = [self.people objectAtIndex:row];

    if ([[column identifier] isEqualToString:@"name"]) {
        result = [person name];
    } else if ([[column identifier] isEqualToString:@"age"]) {
        result = @([person age]);  // Wrap age, a scalar, as an NSNumber
    } else if ([[column identifier] isEqualToString:@"favoriteColor"]) {
        result = [person favoriteColor];
    } // And so on...

    return result;
}
```
以下代码显示了相同数据源方法的更简洁的实现，该实现利用了兼容键值编码的`Person`对象。仅使用列标识符作为`valueForKey:`方法的键参数来获取对应的属性值。除了更短之外，它还更通用，因为只要列标识符始终与模型对象的属性名称匹配，它在以后添加新列时将继续保持不变。
```
- (id)tableView:(NSTableView *)tableview objectValueForTableColumn:(id)column row:(NSInteger)row
{
    return [[self.people objectAtIndex:row] valueForKey:[column identifier]];
}
```


## 访问集合属性

兼容键值编码的对象以与公开其他类型属性相同的方式公开其To-many relationships类型的属性。可以使用`valueForKey:`和`setValue:forKey:`方法来获取和设置集合对象，就像任何其他对象一样。**但是，当想要操纵这些集合的内容时，使用协议定义的可变代理方法通常是最有效的。**

该协议为访问集合对象定义了三种不同的代理方法，每种方法都有一个键和键路径参数：
- `mutableArrayValueForKey:`和`mutableArrayValueForKeyPath:`：它们返回一个代理对象，该代理对象的行为类似于`NSMutableArray`对象。
- `mutableSetValueForKey:`和`mutableSetValueForKeyPath:`：它们返回一个代理对象，该代理对象的行为类似于`NSMutableSet`对象。
- `mutableOrderedSetValueForKey:`和`mutableOrderedSetValueForKeyPath:`：它们返回一个代理对象，该代理对象的行为类似于`NSMutableOrderedSet`对象。

当对代理对象执行向其添加对象和从中删除或者替换对象的操作时，协议的默认实现会相应地修改集合对象。**这比使用`valueForKey:`方法获取不可变的集合对象，根据该集合对象创建一个包含已修改的内容的集合对象，然后使用`setValue:forKey:`方法将其存储回对象更加有效。在许多情况下，它也比直接使用可变集合属性更有效。**这些方法为集合对象中保存的对象提供了保持KVO兼容的额外好处（有关详细信息，请参看[KVO键值观察（Key-Value Observing）](https://www.jianshu.com/p/ab5a36728dfc)）。


## 使用集合运算符

当向兼容键值编码的对象发送`valueForKeyPath:`消息时，可以在键路径中嵌入一个集合运算符。集合运算符是一个开头是`@`符号的关键字，它告知getter在返回之前应该以某种方式操作数据。`NSObject`提供的`valueForKeyPath:`方法的默认实现实现了这种行为。

当键路径包含一个集合运算符时，在运算符之前的键路径部分（成为左键路径）表示`valueForKeyPath`消息的接收者对象的集合。如果将消息直接发送给集合对象（例如`NSArray`实例），则略去左键路径。

运算符之后的键路径部分（称为右键路径）指定运算符要操作的集合的属性。除`@count`之外的所有集合运算符都需要右键路径。下图说明了运算符键路径格式。

![图2-1 运算符键路径格式.png](http://upload-images.jianshu.io/upload_images/4906302-dd3441509bc3aa8c.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

集合运算符表现出三种基本类型的行为：
- 聚合运算符以某种方式合并集合中的对象，并返回与右键路径中指定的属性的数据类型相匹配的单个对象。`@count`运算符是一个例外，其没有右键路径，并总是返回一个`NSNumber`实例。
- 数组运算符返回一个包含指定的集合中所保存对象的子集的`NSArray`实例。
- 嵌套运算符处理包含其他集合的集合，并返回一个`NSArray`或者`NSSet`实例，具体取决于运算符，它以某种方式合并嵌套集合中的对象。

### 样本数据

以下描述包括演示如何调用每个运算符的代码片段，以及执行此运算的结果。它们依赖于上文提到的`BankAccount`类，它包含一个含有`Transaction`对象的数组。每个`Transaction`对象代表一个简单的支票簿条目，如下所示。
```
@interface Transaction : NSObject

@property (nonatomic) NSString* payee;   // To whom
@property (nonatomic) NSNumber* amount;  // How much
@property (nonatomic) NSDate* date;      // When

@end
```
为了讨论，假设现在有一个`BankAccount`实例有一个填充了下表所示数据的`transactions`数组。

| payee values | amount values formatted as currency | date values formatted as month day, year |
|-----------------|--------------------------------------------|-------------------------------------------------|
| Green Power | $120.00 | Dec 1, 2015 |
| Green Power | $150.00 | Jan 1, 2016 |
| Green Power | $170.00 | Feb 1, 2016 |
| Car Loan | $250.00 | Jan 15, 2016 |
| Car Loan | $250.00 | Feb 15, 2016 |
| Car Loan | $250.00 | Mar 15, 2016 |
| General Cable | $120.00 | Dec 1, 2015 |
| General Cable | $155.00 | Jan 1, 2016 |
| General Cable | $120.00 | Feb 1, 2016 |
| Mortgage | $1,250.00 | Jan 15, 2016 |
| Mortgage | $1,250.00 | Feb 15, 2016 |
| Mortgage | $1,250.00 | Mar 15, 2016 |
| Animal Hospital | $600.00 | Jul 15, 2016 |

### 聚合运算符

聚合运算符可以处理数组或者属性集，生成反映集合的某些方面的单个值。

#### @avg

当指定`@avg`运算符时，`valueForKeyPath:`方法会读取集合中每个元素的右键路径指定的属性，将其转换为`double`（用0替换`nil`值），并计算这些值的算数平均值，然后将结果存储在一个`NSNumber`实例中并返回该结果。

获取样本数据的平均交易金额：
```
NSNumber *transactionAverage = [self.transactions valueForKeyPath:@"@avg.amount"];
```
`transactionAverage`的格式化结果为$456.54。

#### @count

当指定`@count`运算符时，`valueForKeyPath:`方法使用一个`NSNumber`实例来返回集合中的对象数量。右键路径（如果存在）将被忽略。

获取`transactions`数组中`Transaction`对象的数量：
```
NSNumber *numberOfTransactions = [self.transactions valueForKeyPath:@"@count"];
```
`numberOfTransactions`的值是13。

#### @max

当指定`@max`运算符时，`valueForKeyPath:`方法查找右键路径指定的集合元素的属性，并返回值最大的一个。查找时使用`compare:`方法进行比较，许多Foundation类定义了该方法，例如`NSNumber`类。**因此，右键路径标识的属性必须持有一个能够对`compare:`消息进行响应的对象**。查找会忽略值为`nil`的属性。

获取样本数据中`Transaction`对象的`date`属性的最大值：
```
NSDate *latestDate = [self.transactions valueForKeyPath:@"@max.date"];
```
`latestDate`的格式化值为Jul 15, 2016。

#### @min

当指定`@min`运算符时，`valueForKeyPath:`方法查找右键路径指定的集合元素的属性，并返回值最小的一个。查找时使用`compare:`方法进行比较，许多Foundation类定义了该方法，例如`NSNumber`类。**因此，右键路径标识的属性必须持有一个能够对`compare:`消息进行响应的对象**。查找会忽略值为`nil`的属性。

获取样本数据中`Transaction`对象的`date`属性值的最小值：
```
NSDate *earliestDate = [self.transactions valueForKeyPath:@"@min.date"];
```
`earliestDate`的格式化值为Dec 1, 2015。

#### @sum

当指定`@sum`运算符时，`valueForKeyPath:`方法读取集合中每个元素的右键路径指定的属性，将其转换为`double`（用0替换`nil`值），并计算这些值的总和，然后将结果存储在一个`NSNumber`实例中并返回该结果。

获取样本数据的交易总金额：
```
NSNumber *amountSum = [self.transactions valueForKeyPath:@"@sum.amount"];
```
`amountSum`的格式化结果为$5,935.00。

### 数组运算符

数组运算符会使得`valueForKeyPath:`方法返回一个与右键路径标识的特定对象集对应的对象数组。

> **重要**：如果使用数组运算符时，任何叶对象为`nil`，`valueForKeyPath:`方法会引发异常。

#### @distinctUnionOfObjects

当指定`@distinctUnionOfObjects`运算符时，`valueForKeyPath:`方法创建并返回一个数组，该数组包含与右键路径标识的属性对应的集合的不同对象。

获取样本数据中`transactions`数组中所有`Transaction`对象的**不同的**`payee`属性值的集合：
```
NSArray *distinctPayees = [self.transactions valueForKeyPath:@"@distinctUnionOfObjects.payee"];
```
生成的`distinctPayees`数组包含Car Loan，General Cable，Animal Hospital，Green Power，Mortgage。

#### @unionOfObjects

当指定`@unionOfObjects`运算符时，`valueForKeyPath:`方法创建并返回一个数组，该数组包含与右键路径标识的属性对应的集合中的所有对象。**与`@distinctUnionOfObjects`不同，其不会删除重复的对象**。

获取样本数据中`transactions`数组中所有`Transaction`对象的`payee`属性值的集合：
```
NSArray *payees = [self.transactions valueForKeyPath:@"@unionOfObjects.payee"];
```
生成的`payees`数组包含Green Power，Green Power，Green Power，Car Loan，Car Loan，Car Loan，General Cable，General Cable，General Cable，Mortgage，Mortgage，Mortgage，Animal Hospital。

### 嵌套运算符

嵌套运算符对嵌套集合进行操作，该集合的每个条目都包含一个集合。

> **重要**：如果使用嵌套运算符时，任何叶对象为`nil`，`valueForKeyPath:`方法会引发异常。

为方便描述，假设存在填充了以下数据的被称为`moreTransactions`的第二个数据数组，并于上文中起始的`transactions`数组一起收集到一个嵌套数组中：
```
NSArray* moreTransactions = @[transactionData];
NSArray* arrayOfArrays = @[self.transactions, moreTransactions];
```

| payee values | amount values formatted as currency | date values formatted as month day, year |
|-----------------|--------------------------------------------|-------------------------------------------------|
| General Cable - Cottage | $120.00 | Dec 18, 2015 |
| General Cable - Cottage | $155.00 | Jan 9, 2016 |
| General Cable - Cottage | $120.00 | Dec 1, 2016 |
| Second Mortgage | $1,250.00 | Nov 15, 2016 |
| Second Mortgage | $1,250.00 | Sep 20, 2016 |
| Second Mortgage | $1,250.00 | Feb 12, 2016 |
| Hobby Shop | $600.00 | Jul 14, 2016 |

#### @distinctUnionOfArrays

当指定`@distinctUnionOfArrays`运算符时，`valueForKeyPath:`方法创建并返回一个数组，该数组包含与右键路径标识的属性对应的所有集合的组合的不同（删除重复项）对象。

获取`arrayOfArrays`数组中的所有数组中的`payee`属性的不同值：
```
NSArray *collectedDistinctPayees = [arrayOfArrays valueForKeyPath:@"@distinctUnionOfArrays.payee"];
```
生成的`collectedDistinctPayees`数组包含Hobby Shop，Mortgage，Animal Hospital，Second Mortgage，Car Loan，General Cable - Cottage，General Cable，Green Power。

#### @unionOfArrays

当指定`@unionOfArrays`运算符时，`valueForKeyPath:`方法创建并返回一个数组，该数组包含与右键路径标识的属性对应的所有集合的组合的所有（不会删除重复项）对象。

获取`arrayOfArrays`数组中的所有数组中的`payee`属性的所有值：
```
NSArray *collectedPayees = [arrayOfArrays valueForKeyPath:@"@unionOfArrays.payee"];
```
生成的`collectedPayees`数组包含Green Power，Green Power，Green Power，Car Loan，Car Loan，Car Loan，General Cable，General Cable，General Cable，Mortgage，Mortgage，Mortgage，Animal Hospital，General Cable - Cottage，General Cable - Cottage，General Cable - Cottage，Second Mortgage，Second Mortgage，Second Mortgage，Hobby Shop。

#### @distinctUnionOfSets

当指定`@distinctUnionOfSets`运算符时，`valueForKeyPath:`方法创建并返回一个`NSSet`对象，该对象包含与右键路径标识的属性对应的所有集合的组合的不同对象。

此运算符的行为与`@distinctUnionOfArrays`类似，不同之处在于它需要一个`NSSet`实例，该实例包含的也是`NSSet`实例，而不是一个包含`NSArray`实例的`NSArray`实例。 此外，它返回的也是一个`NSSet`实例。 假设示例数据已存储在集合而不是数组中，示例调用和结果与`@distinctUnionOfArrays`显示的相同。

## 表示非对象值

`NSObject`提供的键值编码协议方法的实现同时支持对象属性和非对象属性。默认实现自动在对象参数或者返回值与非对象属性之间进行转换。这使得即使存储的属性是标量或者结构体，基于键的setter和getter的签名也保持一致。

当调用协议的其中一个getter（例如`valueForKey:`）时，默认实现将根据[访问器查找方式](#turn)中描述的规则确定特定的为指定键提供值的访问器方法或者实例变量。如果返回值不是对象，则getter使用该值初始化一个`NSNumber`对象（对于标量）或者`NSValue`对象（对于结构体）并返回该值。

类似地，默认情况下，setter（例如`setValue:forKey:`）在给定特定键时确定一个属性的访问器或者实例变量所需要的数据类型。如果数据类型不是对象类型，则setter首先向传入的值对象发送一个适当的`<type>Value`消息来提取基础数据，并存储该数据。

> **注意**：当使用非对象属性的`nil`值调用键值编码协议setter的其中一个时，setter会向setter消息的接收对象发送一个`setNilValueForKey:`消息。该方法的默认实现会引发`NSInvalidArgumentException`异常，但子类可以覆盖此行为，如[处理非对象值](#turn)中所述，例如设置标记值或者提供有意义的默认值。

### 包装和解包标量类型

下表列出了默认的键值编码实现使用`NSNumber`实例包装的标量类型。对于每种数据类型，该表显示了用于将基础属性值初始化为一个`NSNumber`实例以作为getter返回值的创建方法，还显示了用于在设置操作期间从setter输入参数中提取值的访问器方法。

| Data type | Creation method | Accessor method |
|-------------|--------------------|----------------------|
| BOOL | numberWithBool: | boolValue (in iOS) <br> charValue (in macOS)* |
| char | numberWithChar: | charValue |
| double | numberWithDouble: | doubleValue |
| float | numberWithFloat: | floatValue |
| int | numberWithInt: | intValue | 
| long | numberWithLong: | longValue |
| long long | numberWithLongLong: | longLongValue |
| short | numberWithShort: | shortValue |
| unsigned char | numberWithUnsignedChar: | unsignedChar |
| unsigned int | numberWithUnsignedInt: | unsignedInt |
| unsigned long | numberWithUnsignedLong: | unsignedLong |
| unsigned long long | numberWithUnsignedLongLong: | unsignedLongLong |
| unsigned short | numberWithUnsignedShort: | unsignedShort |

> **注意**：在macOS中，由于历史原因，`BOOL`被定义为`signed char`类型，而KVC不会区分这点。因此，当key所标识的属性为`BOOL`类型时，不应该传递诸如`@"ture"`和`@"YES"`这样的字符串作为value给`setValue:forKey:`方法。否则，由于`BOOL`为`char`类型，KVC将尝试调用`charValue`方法，但`NSString`没有实现此方法，这会导致运行时错误。取而代之的是，传递一个`NSNumber`对象，例如`@(1)`或者`@(YES)`，作为`setValue:forKey:`的value参数。此限制不适用于iOS，iOS中的`BOOL`被定义为`bool`类型，而KVC调用`boolValue`方法，该方法适用于`NSNumber`对象或格式正确的`NSString`对象。

### 包装和解包结构体

下表显示了默认访问器用于包装和解包常见的`NSPoint`、`NSRange`、`NSRect`和`NSSize`结构体的创建方法和访问器方法。

| Data type | Creation method | Accessor method |
|------------|---------------------|----------------------|
| NSPoint | valueWithPoint: | pointValue |
| NSRange | valueWithRange: | rangeValue |
| NSRect | valueWithRect: (macOS only). | rectValue |
| NSSize | valueWithSize: | sizeValue |

自动包装和解包并不只限于`NSPoint`、`NSRange`、`NSRect`和`NSSize`，结构体类型可以包装在`NSValue`对象中，如下所示。
```
typedef struct {
    float x, y, z;
} ThreeFloats;

@interface MyClass

@property (nonatomic) ThreeFloats threeFloats;

@end
```
使用`MyClass`类的实例时，可以使用键值编码获取`threeFloats`的值：
```
NSValue *result = [myClass valueForKey:@"threeFloats"];
```
同样，可以使用键值编码设置`threeFloats`的值：
```
hreeFloats floats = {1., 2., 3.};
NSValue* value = [NSValue valueWithBytes:&floats objCType:@encode(ThreeFloats)];
[myClass setValue:value forKey:@"threeFloats"];
```

## 验证属性

键值编码协议定义了支持属性验证的方法。就像使用基于键的访问器来读取和写入兼容键值编码的对象的属性一样，也可以通过键（或键路径）来验证属性。当调用`validateValue:forKey:error:`方法（或者`validateValue:forKeyPath:error:`方法）时，协议的默认实现会在接收验证消息的对象（或者键路径标识的属性所属对象）中查找方法名称与格式`validate<Key>:error:`相匹配的方法。如果对象没有此类方法，则默认验证成功并且返回`YES`。当存在特定于属性的验证方法时，默认实现将返回调用该方法的结果。

> **注意**：仅在Objective-C中使用属性验证。

由于特定于属性的验证方法通过引用接收值和错误参数，所以验证有三种可能的结果：
- 验证方法认为值对象有效并返回`YES`，且不会更改值对象或提示错误。
- 验证方法认为值对象无效，但选择不更改它。 在这种情况下，该方法返回`NO`并将错误引用（如果调用者提供）指向一个`NSError`对象，该对象指示失败的原因。
- 验证方法认为值对象无效，但会创建一个新的有效对象作为替补。 在这种情况下，该方法返回`YES`，同时将错误引用指向一个`NSError`对象。 在返回之前，该方法修改值引用以指向新的值对象。 当执行修改时，该方法总是创建一个新对象，而不是修改旧对象，即使值对象是可变的。

以下代码显示了如何为名称字符串调用验证的示例：
```
Person* person = [[Person alloc] init];
NSError* error;
NSString* name = @"John";
if (![person validateValue:&name forKey:@"name" error:&error]) 
{
    NSLog(@"%@",error);
}
```

### 自动验证

通常情况下，键值编码协议及其默认实现都不会定义任何自动执行验证的机制。但是可以在应用程序需要时，手动使用验证方法。

某些Cocoa技术在某些情况下会自动执行验证。例如，Core Data会在保存管理对象上下文时自动执行验证（请参看[Core Data Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/index.html#//apple_ref/doc/uid/TP40001075)）。此外，在macOS中，Cocoa绑定允许我们指定应自动执行验证（有关详细信息，请参看[Cocoa Bindings Programming Topics](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CocoaBindings/CocoaBindings.html#//apple_ref/doc/uid/10000167i)）。


## 访问器查找方式

`NSObject`提供的`NSKeyValueCoding`协议的默认实现使用明确定义的规则集将基于键的访问器调用映射到对象的属性。这些协议方法使用键参数在对象中查找访问器、实例变量和遵循某些约定的相关方法。虽然很少需要修改此默认查找，但了解它的工作方式能够帮助我们跟踪键值编码对象的行为和使我们自己的对象兼容键值编码。

> **注意：本节中的描述使用`<key>`和`<Key>`作为在键值编码协议方法中的键字符串参数的占位符。协议方法将占位符用作辅助方法调用或变量名查找的一部分。映射的属性名称取决于占位符。例如，对于get访问器`<key>`和`is<Key>`，名为`hidden`的属性映射到`hidden`和`isHidden`。**

### Getter的查找方式

给定一个键参数作为输入，在接收`valueForKey:`调用的类实例中，`valueForKey:`的默认实现会执行以下过程：
1. 在实例中按顺序依次查找名为`get<Key>`、`<key>`、`is<Key>`或者`_<key>`的访问器方法。如果存在某个方法，则调用该方法并跳到第5步。否则，执行第**2**步。

2. 在实例中查找名为`countOf<Key>`、`objectIn<Key>AtIndex:`（对应于`NSArray`类定义的原始方法）和`<key>AtIndexes:`（对应于`NSArray`的`objectsAtIndexes:`方法）的方法。如果找到第一个方法和其他两个方法中的至少一个，则创建一个响应`NSArray`类所有方法的集合代理对象，并返回该对象，查找完成。否则，执行第**3**步。（代理对象随后将其接收的任何`NSArray`消息转换为`countOf<Key>`、`objectIn<Key>AtIndex:`和`<key>AtIndexes:`消息的某种组合并发送给原始对象。如果原始对象还实现了名为`get<Key>:range:`的可选方法，则代理对象也会在适当时使用该方法。实际上，代理对象与兼容键值编码的对象一起工作，使得底层集合属性的行为就像该属性是`NSArray`一样，即使它并不是。）
    
3. 在实例中查找名为`countOf<Key>`、`enumeratorOf<Key>`和`memberOf<Key>:`（对应于`NSSet`类定义的原始方法）的三种方法。如果三种方法全部存在，则创建一个响应`NSSet`类所有方法的集合代理对象，并返回该对象，查找完成。否则执行第**4**步。（代理对象随后将其接收的任何`NSSet`消息转换为`countOf<Key>`、`enumeratorOf<Key>`和`memberOf<Key>:`消息的某种组合并发送给原始对象。实际上，代理对象与兼容键值编码的对象一起工作，使得底层集合属性的行为就像该属性是`NSSet`一样，即使它并不是。）
    
4. 如果没有找到简单的访问器方法或者集合访问方法组，并且实例的类方法`accessInstanceVariablesDirectly`返回`YES`，则按顺序依次查找名为`_<key>`、`_is<Key>`、`<key>`或者`is<Key>`的实例变量。如果存在，则直接获取实例变量的值并执行第**5**步。否则，执行第**6**步。

5. 如果检索到的属性值是一个对象指针，则返回该结果，查找完成。
    如果属性值是`NSNumber`支持的标量类型，则将其存储在`NSNumber`实例中并返回该值，查找完成。
    如果属性值是`NSNumber`不支持的标量类型，则将其转换为`NSValue`对象并返回该值，查找完成。
    
6. 如果以上所有查找都失败了，则调用`valueForUndefinedKey:`方法。 默认情况下，这会引发异常，但`NSObject`的子类可能会提供特定于键的行为。


### Setter的查找方式

给定键和值参数作为输入，在接收`setValue:forKey:`调用的类实例中，`setValue:forKey:`的默认实现会执行以下过程：
1. 按顺序依次查找名为`set<Key>:`或者`_set<Key>`的访问器方法。如果存在某个方法，则使用输入的值调用该方法来设置属性值，查找完成。否则，执行第**2**步。

2. 如果未找到简单的访问器方法，并且实例的类方法`accessInstanceVariablesDirectly`方法返回`YES`，则按顺序依次查找名为`_<key>`、`_is<Key>`、`<key>`或者`is<Key>`的实例变量。如果存在，则直接使用输入的值来设置变量，查找完成。否则，执行第**3**步。

3. 如果未找到访问器方法和实例变量，则调用`setValue:forUndefinedKey:`方法。默认情况下，这会引发异常，但`NSObject`的子类可能会提供特定于键的行为。


### 可变数组的查找方式

给定键和值参数作为输入，`mutableArrayValueForKey:`的默认实现会为名称为`<key>`的属性返回一个可变代理数组，其执行以下过程：
1. 查找一对名为`insertObject:in<Key>AtIndex:`和`removeObjectFrom<Key>AtIndex:`（对应于`NSMutableArray`类的原始方法）的方法，或者名为`insert<Key>:atIndexes:`和`remove<Key>AtIndexes:`（对应于`NSMutableArray`的`insertObjects:atIndexes:`和`removeObjectsAtIndexes:`）的方法。如果至少存在一对插入和删除方法，则返回一个能够响应`NSMutableArray`消息的代理对象，查找完成。（代理对象随后会将接收到的`NSMutableArray`消息转换为`insertObject:in<Key>AtIndex:`、`removeObjectFrom<Key>AtIndex:`、`insert<Key>:atIndexes:`和`remove<Key>AtIndexes:`消息的某种组合发送给接收`mutableArrayValueForKey:`消息的原始对象。当原始对象实现了一个可选的名为`replaceObjectIn<Key>AtIndex:withObject:`或者`replace<Key>AtIndexes:with<Key>:`的替换对象方法时，代理对象会在适当时间使用它们以获得最佳性能。）

 2. 如果不存在一对插入和删除方法，会查找名为`set<Key>:`的访问器方法。如果存在该方法，则返回一个能够响应`NSMutableArray`消息的代理对象，查找完成。（该代理对象与第**1**步中返回的代理对象有所不同，其是通过发送`set<Key>:`消息给接收`mutableArrayValueForKey:`消息的原始对象来响应`NSMutableArray`消息的。）

> **注意**：第2步中描述的机制比第1步的效率要低得多，因为它可能涉及重复创建新的集合对象而不是修改现有的集合对象。因此，在设计我们自己的兼容键值编码的对象时，通常应该避免使用该机制。

3. 如果可变数组方法和访问器方法都不存在，并且原始对象的`accessInstanceVariablesDirectly`方法返回`YES`，则按顺序依次查找名为`_<key>`或者`<key>`的实例变量。
    如果存在实例变量，则返回一个代理对象。该代理对象会将其接收到的所有`NSMutableArray`消息转发给实例变量的值，该值通常是`NSMutableArray`或其子类之一的实例。

4. 如果以上所有步骤都失败，则返回一个可变集合代理对象。该对象在收到`NSMutableArray`的消息时，向原始对象发送一个`setValue:forUndefinedKey:`消息。
    `setValue:forUndefinedKey:`的默认实现会引发一个`NSUndefinedKeyException`，但子类可能会覆盖此行为。
    

### 可变有序集合的查找方式

`mutableOrderedSetValueForKey:`的默认实现识别与`valueForKey:`相同的简单访问器方法和有序集合访问器方法，并遵循相同的直接访问实例变量策略。但是，其返回的是一个可变集合代理对象，而`valueForKey:`方法返回的是一个不可变集合代理对象。此外，它还执行以下操作：
1. 查找一对名为`insertObject:in<Key>AtIndex:`和`removeObjectFrom<Key>AtIndex:`（对应于`NSMutableOrderedSet`类定义的这两个最原始的方法）的方法，或者名为`insert<Key>:atIndexes:`和`remove<Key>AtIndexes:`（对应于`NSMutableOrderedSet`类的`insertObjects:atIndexes:`和`removeObjectsAtIndexes:`）的方法。
    如果至少存在一对插入和删除方法，则返回一个能够响应`NSMutableOrderedSet`消息的代理对象。代理对象随后会将接收到的`NSMutableOrderedSet`消息转换为`insertObject:in<Key>AtIndex:`、`removeObjectFrom<Key>AtIndex:`、`insert<Key>:atIndexes:`和`remove<Key>AtIndexes:`消息的某种组合发送给接收`mutableOrderedSetValueForKey:`消息的原始对象。
    当原始对象实现了一个可选的`replaceObjectIn<Key>AtIndex:withObject:`或者`replace<Key>AtIndexes:with<Key>:`的方法时，代理对象会在适当时间使用它们。
    
2. 如果未找到可变有序集合方法，则查找名为`set<Key>:`的访问器。在这种情况下，会返回一个代理对象。该代理对象每次接收到`NSMutableOrderedSet`消息时，会发送一个`set<Key>:`消息给接收`mutableOrderedSetValueForKey:`消息的原始对象。

> **注意**：第2步中描述的机制比第1步的效率要低得多，因为它可能涉及重复创建新的集合对象而不是修改现有的集合对象。因此，在设计我们自己的兼容键值编码的对象时，通常应该避免使用该机制。

3. 如果可变有序集合方法和访问器方法都不存在，并且原始对象的`accessInstanceVariablesDirectly`方法返回`YES`，则按顺序依次查找名为`_<key>`或者`<key>`的实例变量。如果存在实例变量，则返回一个代理对象。该代理对象会将其接收到的所有`NSMutableOrderedSet`消息转发给实例变量的值，该值通常是`NSMutableOrderedSet`或其子类之一的实例。

4. 如果以上所有步骤都失败，则返回一个代理对象。该对象在收到`NSMutableOrderedSet`的消息时，向原始对象发送一个`setValue:forUndefinedKey:`消息。
    `setValue:forUndefinedKey:`的默认实现会引发一个`NSUndefinedKeyException`，但子类可能会覆盖此行为。


### 可变集合的查找方式

给定一个键参数作为输入，`mutableSetValueForKey:`方法的默认实现为原始对象的名为`<key>`的数组属性返回一个可变代理集合，其会执行以下过程：
1. 查找一对名为`add<Key>Object:`和`remove<Key>Object:`的方法（对应于`NSMutableSet`的原始方法`addObject:`和`removeObject:`），或者名为`add<Key>:`和`remove<Key>:`的方法（对应于`NSMutableSet`的`unionSet:`和`minusSet:`方法）。如果至少存在一对插入和删除方法，则返回一个能够响应`NSMutableSet`消息的代理对象。代理对象随后会将接收到的`NSMutableSet`消息转换为`add<Key>Object:`、`remove<Key>Object:`、`addObject:`和`removeObject:`消息的某种组合发送给接收`mutableSetValueForKey:`消息的原始对象。
    当原始对象实现了一个名为`intersect<Key>:`或者`set<Key>:`的方法时，代理对象会在适当时间使用它们以获得最佳性能。

2. 如果`mutableSetValueForKey:`消息的接收者是一个managed object，则查找模式不会像non-managed object那样继续。 有关详细信息，请参看[Core Data Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/index.html#//apple_ref/doc/uid/TP40001075)。

3. 如果未找到可变集合方法，并且原始对象不是一个managed object，则会查找名为`set<Key>:`的访问器方法。如果存在该方法，则返回一个代理对象。该对象每次接收到`NSMutableSet`消息时，会向原始对象发送一个`set<Key>:`消息。

> **注意**：第3步中描述的机制比第1步的效率要低得多，因为它可能涉及重复创建新的集合对象而不是修改现有的集合对象。因此，在设计我们自己的兼容键值编码的对象时，通常应该避免使用该机制。

4. 如果未找到可变集合方法和访问器方法，并且原始对象的`accessInstanceVariablesDirectly`方法返回`YES`，则按顺序依次查找名为`_<key>`或者`<key>`的实例变量。如果存在实例变量，则返回一个代理对象。该代理对象会将其接收到的所有`NSMutableSet`消息转发给实例变量的值，该值通常是`NSMutableSet`或其子类之一的实例。

5. 如果以上所有步骤都失败，则返回一个代理对象。该对象在收到`NSMutableSet`的消息时，向原始对象发送一个`setValue:forUndefinedKey:`消息。


## 实现基本的键值编码兼容

当对对象采用键值编码时，依赖于对象从`NSObject`类继承的`NSKeyValueCoding`协议的默认实现。反过来，默认实现依赖于我们根据某些明确的格式来定义对象的实例变量和访问器方法，以便在接收键值编码消息时，它可以将键字符串与属性相关联。

通常，通过使用`@property`语句声明属性并允许编译器自动合成实例变量（ivar）和访问器来遵循Objective-C中的标准格式。默认情况下，编译器遵循预期的格式。

如果需要在Objective-C中**手动实现**访问器或实例变量，请遵循本节中的指导原则来维护基本的兼容性。

### 基本的Getter

要实现返回属性值的getter，同时可能还要执行其他自定义工作，请使用名称为该属性名的方法，例如`title`字符串属性：
```
- (NSString*)title
{
    // Extra getter logic…

    return _title;
}
```
对于保存布尔值的属性，也可以使用前缀为**is**的方法，例如`hidden`布尔属性：
```
- (BOOL)isHidden
{
    // Extra getter logic…

    return _hidden;
}
```
当属性是标量或者结构体时，键值编码的默认实现将值包装在对象中，以便在协议方法的接口上使用，如[表示非对象值](#turn)中所述，无需执行任何特殊操作就可支持此行为。

### 基本的Setter

要实现存储属性值的setter，请使用名称为带有前缀**set**的首字母大写的属性名的方法。 对于`hidden`属性：
```
- (void)setHidden:(BOOL)hidden
{
    // Extra setter logic…

    _hidden = hidden;
}
```

> **警告**：不要在`set<Key>:`方法中调用[验证属性](#turn)中描述的验证方法。

当属性是非对象类型（例如`hidden`布尔）时，协议的默认实现会检测基础数据类型，并在将其应用于setter之前，解包传递给`setValue:forKey:`方法的对象值（在本例中是一个`NSNumber`实例），如[表示非对象值](#turn)中所述。但是，如果有可能将`nil`值写入非对象属性，则覆盖`setNilValueForKey:`方法来处理这种情况，如[处理非对象值](#turn)中所述。`hidden`属性的处理方式只是将`nil`解释为`NO`：
```
- (void)setNilValueForKey:(NSString *)key
{
    if ([key isEqualToString:@"hidden"]) {
        [self setValue:@(NO) forKey:@”hidden”];
    } else {
        [super setNilValueForKey:key];
    }
}
```
如果有必要，即使允许编译器合成setter，我们也可以提供上述方法覆盖。

### 实例变量

当某个键值编码访问器方法（例如`valueForKey:`）的默认实现无法查找到属性的访问器时，它会询问调用`accessInstanceVariablesDirectly`方法来询问该类是否允许直接使用实例变量。默认情况下，此类方法返回`YES`，但可以覆盖此方法返回`NO`。

如果允许使用实例变量，请确保使用带下划线`_`前缀的属性名来命名它们。通常情况下，编译器在自动合成属性时会执行此操作。但如果使用显式的`@synthesize`指令，则可以手动执行这种命名操作。
```
@synthesize title = _title;
```
在某些情况下，会使用`@dynamic`指令告知编译器将在运行时提供getter和setter，而不是使用`@synthesize`或者允许编译器自动合成属性。可以通过这样做来避免自动合成setter，以便可以提供集合访问器，如[定义集合方法](#turn)中所述。在这种情况下，手动声明实例变量作为接口声明的一部分。
```
@interface MyObject : NSObject {
    NSString* _title;
}

@property (nonatomic) NSString* title;

@end
```

## 定义集合方法

当使用标准命名约定来创建访问器和实例变量时，键值编码协议的默认实现可以定位到它们以响应键值编码消息。对于表示to-many relationships（请看[访问对象属性](#turn)中的描述）的集合对象，情况和其他属性一样。但是，如果实现了集合访问器，而不是集合属性的基本访问器，则可以：
- 与`NSArray`和`NSSet`以外的类建立to-many relationships。在对象中实现集合方法时，getter的默认实现返回一个代理对象，代理对象会调用这些集合方法来响应它接收到的`NSArray`和`NSSet`消息。底层属性对象不必是`NSArray`和`NSSet`的实例，因为代理对象会使用这些集合方法来提供预期的行为。
- 在改变to-many relationships的内容时，提供更好的性能。协议的默认实现会使用集合方法来改变属性，而不是使用基本的setter重复创建新的集合对象来响应每个更改。
- 为对象的集合属性的内容提供键值观察兼容的访问。有关键值观察的更多信息，请参看[KVO键值观察（Key-Value Observing）](https://www.jianshu.com/p/ab5a36728dfc)。

可以实现两类集合访问器中的一种，具体取决于是希望关系的行为类似于一个索引的、有序的集合（如`NSArray`对象），还是一个无序的、唯一的集合（如`NSSet`对象）。在任何一种情况下，都要至少实现一组方法来支持对属性的读取访问，然后添加一个额外的集合来使集合的内容的突变成为可能。

> **注意**：键值编码协议未声明本节中描述的方法。取而代之的是，`NSObject`提供的协议的默认实现会在兼容键值编码的对象中查找这些方法，如[访问器查找方式]中所述，并使用它们来处理作为协议的一部分的键值编码消息。



### 访问索引集合

添加索引访问器方法来提供一个计算、检索、添加和替换有序关系中的对象的机制。底层对象通常是`NSArray`或者`NSMutableArray`的实例，但是如果提供集合访问器，则使得实现了这些方法的任何对象像数组一样被操作成为了可能。

#### 索引集合Getter

对于一个没有默认getter的集合属性，如果提供以下索引集合getter方法，协议的默认实现在响应`valueForKey:`消息时，会返回一个行为类似于`NSArray`的代理对象，但该代理对象调用这些集合方法来执行其工作。

> **注意**：在现代Objective-C中，编译器默认为每个属性合成一个getter，因此默认实现不会使用本节中的方法创建只读代理（请查看[Getter的查找方式](#turn)）。 可以通过不声明属性（仅依赖于ivar）或将属性声明为`@dynamic`（告知编译器会在运行时提供访问器行为）来解决此问题。 无论哪种方式，编译器都不会提供默认的getter，并且默认实现会使用以下方法。

- `countOf<Key>`：此方法将to-many relationship中的对象数作为`NSUInteger`返回，就像数组的原始方法`count`一样。实际上，当底层属性是一个`NSArray`时，使用`count`方法返回结果。
    例如，对于表示一个银行交易列表的to-many relationship，由名为为`transactions`的`NSArray`支持：
```
- (NSUInteger)countOfTransactions {
    return [self.transactions count];
}
```

- `objectIn<Key>AtIndex:`或者`<key>AtIndexes:`：第一个方法返回to-many relationship中在指定的索引位置的对象，而第二个方法返回在由`NSIndexSet`参数指定的索引位置的对象数组。 它们分别对应于`NSArray`方法`objectAtIndex:`和`objectsAtIndexes:`，只需要实现其中一个。 `transactions`数组的对应应方法为：
```
- (id)objectInTransactionsAtIndex:(NSUInteger)index {
    return [self.transactions objectAtIndex:index];
}

- (NSArray *)transactionsAtIndexes:(NSIndexSet *)indexes {
    return [self.transactions objectsAtIndexes:indexes];
}
```

- `get<Key>:range:`：此方法是可选的，但可以提高性能。 它返回集合中处于指定范围内的对象，对应于`NSArray`方法`getObjects:range:`。`transactions`数组的实现为：
```
- (void)getTransactions:(Transaction * __unsafe_unretained *)buffer
range:(NSRange)inRange {
    [self.transactions getObjects:buffer range:inRange];
}
```

#### 索引集合Mutator

支持索引访问器的可变的to-many relationship需要实现不同的方法组。当提供这些setter方法时，默认实现在响应`mutableArrayValueForKey:`消息时，返回一个行为类似于`NSMutableArray`对象的代理对象，但该代理对象会使用原始对象的方法来执行其工作。这通常比直接返回`NSMutableArray`对象更有效，它还使得to-many relationship的内容兼容键值观察成为可能。

为了使对象的键值编码兼容一个可变有序的to-many relationship，请实现以下方法：
- `insertObject:in<Key>AtIndex:`或者`insert<Key>:atIndexes:`：第一个方法接收要插入的对象和该对象的索引，第二个方法接收一个对象数组和包含对象数组中每个对象的索引的`NSIndexSet`对象，只需要其中一种方法。它们类似于`NSMutableArray`的`insertObject:atIndex:`和`insertObjects:atIndexes:`方法。
    `transactions`对象被声明为一个`NSMutableArray`：
```
- (void)insertObject:(Transaction *)transaction
inTransactionsAtIndex:(NSUInteger)index {
    [self.transactions insertObject:transaction atIndex:index];
}

- (void)insertTransactions:(NSArray *)transactionArray
atIndexes:(NSIndexSet *)indexes {
    [self.transactions insertObjects:transactionArray atIndexes:indexes];
}
```

- `removeObjectFrom<Key>AtIndex:`或者`remove<Key>AtIndexes:`：第一个方法接收要删除的对象的索引，第二个方法接收一个包含要删除对象的索引的`NSIndexSet`对象，只需要其中一种方法。它们对应于`NSMutableArray`的`removeObjectAtIndex:`和`removeObjectsAtIndexes:`方法。
```
- (void)removeObjectFromTransactionsAtIndex:(NSUInteger)index {
    [self.transactions removeObjectAtIndex:index];
}

- (void)removeTransactionsAtIndexes:(NSIndexSet *)indexes {
    [self.transactions removeObjectsAtIndexes:indexes];
}
```

- `replaceObjectIn<Key>AtIndex:withObject:`或者`replace<Key>AtIndexes:with<Key>:`：这些替换访问器为代理对象提供了一种直接替换集合中的对象的方式，而不必删除一个对象之后再插入一个对象。它们对应于`NSMutableArray`的`replaceObjectAtIndex:withObject:`和`replaceObjectsAtIndexes:withObjects:`方法。
```
- (void)replaceObjectInTransactionsAtIndex:(NSUInteger)index
withObject:(id)anObject {
    [self.transactions replaceObjectAtIndex:index withObject:anObject];
}

- (void)replaceTransactionsAtIndexes:(NSIndexSet *)indexes
withTransactions:(NSArray *)transactionArray {
    [self.transactions replaceObjectsAtIndexes:indexes withObjects:transactionArray];
}
```

### 访问无序集合

添加无序集合访问器方法，以提供一种访问和修改无序关系中的对象的机制。通常，此关系是一个`NSSet`或者`NSMutableSet`对象。 但是，当对象实现了这些访问器时，使得对象像`NSSet`的实例一样操作成为了可能。


#### 无序集合Getter

当提供以下集合getter方法以返回集合中的对象数、迭代集合对象和测试对象是否已存在于集合中时，在响应`valueForKey`消息时，协议的默认实现返回一个行为类似于`NSSet`的代理对象，但其调用以下集合方法来完成其工作。
- `countOf<Key>`：此方法返回关系中的项目数，对应于`NSSet`的`count`方法。当底层对象是`NSSet`时，直接调用此方法。例如，名为`employees`的`NSSet`对象包含`Employee`对象：
```
- (NSUInteger)countOfEmployees {
    return [self.employees count];
}
```

- `enumeratorOf<Key>`：此方法返回一个`NSEnumerator`实例，该实例用于迭代关系中的对象。 该方法对应于`NSSet`的`objectEnumerator`方法。关于`NSEnumerator`的更多信息，请参看[Collections Programming Topics](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Collections/Collections.html#//apple_ref/doc/uid/10000034i)中的[Enumeration: Traversing a Collection’s Elements](#turn)。
```
- (NSEnumerator *)enumeratorOfEmployees {
    return [self.employees objectEnumerator];
}
```

- `memberOf<Key>:`：此方法将传递的对象与集合中的内容进行比较，并将匹配对象作为参数返回。如果未找到匹配的对象，则返回`nil`。如果手动实现，通常使用`isEqual:`方法来比较对象。 当底层对象是`NSSet`对象时，可以使用等效的`member:`方法。
```
- (Employee *)memberOfEmployees:(Employee *)anObject {
    return [self.employees member:anObject];
}
```

#### 无序集合Mutators

支持无序访问器的可变的to-many relationship需要实现不同的方法组。当提供这些setter方法时，默认实现在响应`mutableSetValueForKey:`消息时，返回一个行为类似于`NSMutableSet`对象的代理对象，但该代理对象会使用原始对象的方法来执行其工作。这通常比直接返回`NSMutableSet`对象更有效，它还使得to-many relationship的内容兼容键值观察成为可能。

为了使对象的键值编码兼容一个可变无序的to-many relationship，请实现以下方法：
- `add<Key>Object:`或者`add<Key>:`：这些方法将一个或者一组对象添加到关系中，向关系添加一组项目时，请确保关系中不存在同样的对象。只需要其中一种方法，它们类似于`NSMutableSet`的`addObject:`和`unionSet:`方法。对于`employees`集：
```
- (void)addEmployeesObject:(Employee *)anObject {
    [self.employees addObject:anObject];
}

- (void)addEmployees:(NSSet *)manyObjects {
    [self.employees unionSet:manyObjects];
}
```

- `remove<Key>Object:`或者`remove<Key>:`：这些方法从关系中删除单个或者一组项目，只需要其中一种方法。它们类似于`NSMutableSet`的`removeObject:`和`minusSet:`方法。例如：
```
- (void)removeEmployeesObject:(Employee *)anObject {
    [self.employees removeObject:anObject];
}

- (void)removeEmployees:(NSSet *)manyObjects {
    [self.employees minusSet:manyObjects];
}
```

- `intersect<Key>:`：此方法接收一个`NSSet`参数，从关系中删除所有不是输入集和集合集公共的对象。 这对应于`NSMutableSet`的`intersectSet:`。例如:
```
- (void)intersectEmployees:(NSSet *)otherObjects {
    return [self.employees intersectSet:otherObjects];
}
```

## 处理非对象值

通常情况下，兼容键值编码的对象依赖于键值编码的默认实现来自动包装和解包非对象属性，如[表示非对象值](#turn)中所述。但是，可以覆盖此默认行为。

如果兼容键值编码的对象接收到一个将`nil`作为非对象属性的值的`setValue:forKey:`消息，`setValue:forKey:`的默认实现会发送一个`setNilValueForKey:`消息给原始对象，该消息的默认实现会引发一个`NSInvalidArgumentException`异常。可以覆盖该方法来提供特定的行为。

```
- (void)setNilValueForKey:(NSString *)key
{
    if ([key isEqualToString:@"age"]) {
        [self setValue:@(0) forKey:@”age”];
    } else {
        [super setNilValueForKey:key];
    }
}
```
> **注意**：当一个对象覆盖了不推荐使用的`unableToSetNilForKey:`方法时，`setValue:forKey:`会调用该方法，而不是`setNilValueForKey`。


## 添加验证

键值编码协议定义了通过键或者键路径来验证属性的方法，这些方法的默认实现依赖于我们定义的一些方法。具体来说，为任何想要验证的属性提供一个`validate<Key>:error:`方法。默认实现在响应`validateValue:forKey:error:`消息时会查找这些方法。

如果没有为属性提供验证方法，则协议的默认实现假定验证该属性成功而不管属性值是什么。

### 实现一个验证方法

当为属性提供一个验证方法时，该方法通过引用接收两个参数：要验证的值对象和用于返回错误信息的`NSError`。验证方法可以执行以下三种操作之一：
- 当值对象有效时，返回`YES`，并且不更改值对象和错误。
- 当值对象无效且不能或不想提供有效的替代方法时，请将`error`参数设置为`NSError`对象，该对象指示失败的原因并返回`NO`。
- 当值对象无效但我们知道有效替代项时，请创建有效对象，将值引用分配给新对象，并返回`YES`且不修改错误引用。 如果提供其他值，则始终返回新对象，而不是修改正在验证的对象，即使原始对象是可变的。

```
- (BOOL)validateName:(id *)ioValue error:(NSError * __autoreleasing *)outError{
    if ((*ioValue == nil) || ([(NSString *)*ioValue length] < 2)) {
        if (outError != NULL) {
            *outError = [NSError errorWithDomain:PersonErrorDomain code:PersonInvalidNameCode userInfo:@{ NSLocalizedDescriptionKey : @"Name too short" }];
        }
        return NO;
    }
    return YES;
}
```
> **重要**：在修改错误引用之前，始终检查错误引用是否为`NULL`。

### 标量值的验证

验证方法的`value`参数是一个对象，因此，非对象属性的值包装在`NSNumber`或者`NSValue`对象中。以下代码演示了标量属性`age`的验证方法。
```
- (BOOL)validateAge:(id *)ioValue error:(NSError * __autoreleasing *)outError {
    if (*ioValue == nil) {
        // Value is nil: Might also handle in setNilValueForKey
        *ioValue = @(0);
    } else if ([*ioValue floatValue] < 0.0) {
        if (outError != NULL) {
            *outError = [NSError errorWithDomain:PersonErrorDomain code:PersonInvalidAgeCode userInfo:@{ NSLocalizedDescriptionKey : @"Age cannot be negative" }];
        }
        return NO;
    }
    return YES;
}
```
