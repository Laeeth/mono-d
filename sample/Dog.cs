using System;

public class Dog
{
    static public void Type()
    {
        Console.WriteLine("a Dog!");
    }
    public void Bark()
    {
        Console.WriteLine("bark!");
    }
    public void Bark(int times)
    {
        for (var i = 0; i < times; ++i )
            Console.WriteLine("bark!");
    }

   public int Squared(int num)
   {
	return num*num;
   }

   public string SquaredString(int num)
   {
     var ret = num * num;
     return ret.ToString();
   }
}
