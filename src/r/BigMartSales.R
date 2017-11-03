path <- "./../../dataCentre/BigMartSales"

setwd(path)
#print(getwd())
train <- read.csv("Train_UWu5bXk.csv")
test <- read.csv("Test_u94Q5KV.csv")

dim(train)
dim(test)

str(train)

table(is.na(train))
colSums(is.na(train))

summary(train)

# install.packages("ggplot2")
# install.packages("rlang")
library(ggplot2)
ggplot(train, aes(x= Item_Visibility, y = Item_Outlet_Sales)) + geom_point(size = 2.5, color="navy") + xlab("Item Visibility") + ylab("Item Outlet Sales") + ggtitle("Item Visibility vs Item Outlet Sales")

ggplot(train, aes(Outlet_Identifier, Item_Outlet_Sales)) + geom_bar(stat = "identity", color = "purple") +theme(axis.text.x = element_text(angle = 70, vjust = 0.5, color = "black"))  + ggtitle("Outlets vs Total Sales") + theme_bw()

ggplot(train, aes(Item_Type, Item_Outlet_Sales)) + geom_bar( stat = "identity") +theme(axis.text.x = element_text(angle = 70, vjust = 0.5, color = "navy")) + xlab("Item Type") + ylab("Item Outlet Sales")+ggtitle("Item Type vs Sales")

ggplot(train, aes(Item_Type, Item_MRP)) +geom_boxplot() +ggtitle("Box Plot") + theme(axis.text.x = element_text(angle = 70, vjust = 0.5, color = "red")) + xlab("Item Type") + ylab("Item MRP") + ggtitle("Item Type vs Item MRP")


print(head(train, num=10L))
print(head(test, num=10L))

test$Item_Outlet_Sales <-  1

combi <- rbind(train, test)
combi$Item_Weight[is.na(combi$Item_Weight)] <- median(combi$Item_Weight, na.rm = TRUE)
table(is.na(combi$Item_Weight))

combi$Item_Visibility <- ifelse(combi$Item_Visibility == 0, median(combi$Item_Visibility), combi$Item_Visibility)
levels(combi$Outlet_Size)[1] <- "Other"
library(plyr)
combi$Item_Fat_Content <- revalue(combi$Item_Fat_Content, c("LF" = "Low Fat", "reg" = "Regular"))
combi$Item_Fat_Content <- revalue(combi$Item_Fat_Content, c("low fat" = "Low Fat"))
table(combi$Item_Fat_Content)

# install.packages("dplyr")
library(dplyr)
a <- combi%>%group_by(Outlet_Identifier)%>%tally()

head(a)
names(a)[2] <- "Outlet_Count"
combi <- full_join(a, combi, by = "Outlet_Identifier")

b <- combi%>%group_by(Item_Identifier)%>%tally()
names(b)[2] <- "Item_Count"
head (b)

c <- combi%>%select(Outlet_Establishment_Year)%>%mutate(Outlet_Year = 2013 - combi$Outlet_Establishment_Year)
head(c)
combi <- full_join(c, combi)

q <- substr(combi$Item_Identifier,1,2)
q <- gsub("FD","Food",q)
q <- gsub("DR","Drinks",q)
q <- gsub("NC","Non-Consumable",q)
table(q)

combi$Item_Type_New <- q

combi$Item_Fat_Content <- ifelse(combi$Item_Fat_Content == "Regular",1,0)

sample <- select(combi, Outlet_Location_Type)
demo_sample <- data.frame(model.matrix(~.-1,sample))
head(demo_sample)

# install.packages("dummies")
library(dummies)
combi <- dummy.data.frame(combi, names = c('Outlet_Size','Outlet_Location_Type','Outlet_Type', 'Item_Type_New'),  sep='_')

