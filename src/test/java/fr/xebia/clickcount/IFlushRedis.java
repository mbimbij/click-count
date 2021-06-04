package fr.xebia.clickcount;

@FunctionalInterface
public interface IFlushRedis {
  void flushAll();
}
