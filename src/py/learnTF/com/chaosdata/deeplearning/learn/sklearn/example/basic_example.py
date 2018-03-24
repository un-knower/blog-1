# coding=utf-8
from sklearn import neighbors, datasets, preprocessing
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score



def knn_exam():
    iris = datasets.load_iris()

    X, y = iris.data[:, :2], iris.target

    X_train, X_test, y_train, y_test = train_test_split(X, y, random_state=33)

    scaler = preprocessing.StandardScaler().fit(X_train)

    X_train = scaler.transform(X_train)
    X_test = scaler.transform(X_test)

    knn = neighbors.KNeighborsClassifier(n_neighbors=5)
    knn.fit(X_train, y_train)

    y_pred = knn.predict(X_test)
    accuracy_score(y_test, y_pred)


def loadDataExam():
    import numpy as np
    X = np.random.random((10, 5))
    y = np.array(['M', 'M', 'F', 'F', 'M', 'F', 'M', 'M'])
    X[X < 0.7] = 0

    print(X)



loadDataExam()