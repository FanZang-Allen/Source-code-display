# neuralnet.py
# ---------------
# Licensing Information:  You are free to use or extend this projects for
# educational purposes provided that (1) you do not distribute or publish
# solutions, (2) you retain this notice, and (3) you provide clear
# attribution to the University of Illinois at Urbana-Champaign
#

import numpy as np
import numpy.linalg as la
import torch
import torch.nn as nn


class NeuralNet(torch.nn.Module):
    def __init__(self, lrate,loss_fn,in_size,out_size):
        """
        Initialize the layers of neural network

        @param lrate: The learning rate for the model.
        @param loss_fn: A loss function defined in the following way:
            @param yhat - an (N,out_size) tensor
            @param y - an (N,) tensor
            @return l(x,y) an () tensor that is the mean loss
        @param in_size: Dimension of input
        @param out_size: Dimension of output

        """
        super(NeuralNet, self).__init__()
        self.loss_fn = loss_fn
        self.in_size = in_size
        self.out_size = out_size
        self.lrate = lrate
        self.conv2dlayer = nn.Sequential(nn.Conv2d(3, 16, kernel_size=5, stride=1, padding=3),
                                         nn.ReLU(),
                                         nn.MaxPool2d(kernel_size=2, stride=2))
        self.linearlayer = nn.Sequential(nn.BatchNorm1d(4624),
                                         nn.Linear(4624,32),
                                         nn.LeakyReLU(),
                                         nn.Linear(32,self.out_size))
        self.dropout = nn.Dropout()
        self.optimizer = torch.optim.SGD(self.parameters(), lr = self.lrate)

    def forward(self, x):
        """ A forward pass of neural net (evaluates f(x)).

        @param x: an (N, in_size) torch tensor

        @return y: an (N, out_size) torch tensor of output from the network
        """
        x = (x - torch.mean(x)) / torch.std(x)
        x = x.view(len(x),3,32,32)
        cnn_result = self.conv2dlayer(x)
        out = cnn_result.view(len(x), -1)
        out = self.dropout(out)
        out = self.linearlayer(out)
        return out

    def step(self, x,y):
        """
        Performs one gradient step through a batch of data x with labels y
        @param x: an (N, in_size) torch tensor
        @param y: an (N,) torch tensor
        @return L: total empirical risk (mean of losses) at this time step as a float
        """
        self.optimizer.zero_grad()
        forward_res = self.forward(x)
        loss = self.loss_fn(forward_res,y)
        loss.backward()
        self.optimizer.step()
        return loss

    def predict(self,x):
        x = (x - torch.mean(x)) / torch.std(x)
        x = x.view(1, 3, 32, 32)
        cnn_result = self.conv2dlayer(x)
        out = cnn_result.view(len(x), -1)
        out = self.linearlayer(out)
        return out


def fit(train_set,train_labels,dev_set,n_iter,batch_size=100):
    """ Make NeuralNet object 'net' and use net.step() to train a neural net
    and net(x) to evaluate the neural net.

    @param train_set: an (N, in_size) torch tensor
    @param train_labels: an (N,) torch tensor
    @param dev_set: an (M,) torch tensor
    @param n_iter: int, the number of iterations of training
    @param batch_size: The size of each batch to train on. (default 100)

    # return all of these:

    @return losses: Array of total loss at the beginning and after each iteration. Ensure len(losses) == n_iter
    @return yhats: an (M,) NumPy array of binary labels for dev_set
    @return net: A NeuralNet object
    """
    train_set = (train_set - torch.mean(train_set)) / torch.std(train_set)
    dev_set = (dev_set - torch.mean(dev_set)) / torch.std(dev_set)
    losses = np.zeros(n_iter)
    net = NeuralNet(0.01, torch.nn.CrossEntropyLoss(), 3072, 2)
    net.train()
    for i in range(n_iter):
        start_index = (100 * i) % len(train_set)
        losses[i] = net.step(train_set[start_index:(start_index + 100), :],
                             train_labels[start_index:(start_index + 100)])
    yhat = np.zeros(len(dev_set))
    net.eval()
    for i in range(len(dev_set)):
        result = net.predict(dev_set[i])
        yhat[i] = torch.argmax(result)
    return losses, yhat, net
