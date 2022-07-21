using IniFile;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace KEHsfx
{
	static class Program
	{
		static void Main(string[] args)
		{
			var sfx = IniSerializer.Deserialize<Dictionary<string, SFXInfo>>("sound/SFX/SFX.ini");
			var dac = IniSerializer.Deserialize<Dictionary<string, DACInfo>>("sound/SFX/DACSFX.ini");
			using (StreamWriter sw = new StreamWriter("sfxbank.gen.asm", false, Encoding.ASCII))
			{
				sw.WriteLine("SoundIndex:");
				foreach (var item in sfx)
					sw.WriteLine("\tzSoundIndexEntry\tSnd_{0},${1:X2}", item.Key, item.Value.Priority);
				sw.WriteLine();
				foreach (var item in sfx)
					sw.WriteLine("Snd_{0}:\tinclude \"sound/SFX/{1}\"", item.Key, item.Value.File);
				sw.WriteLine();
			}
			using (StreamWriter sw = new StreamWriter("dacsfxlist.gen.asm", false, Encoding.ASCII))
			{
				sw.WriteLine("zDACSFXList:");
				foreach (var item in dac)
					sw.WriteLine("\tdb\t{0}", item.Value.Sample);
			}
			using (StreamWriter sw = new StreamWriter("sfxids.gen.asm", false, Encoding.ASCII))
			{
				List<string> musids = new List<string>(sfx.Keys) { "_End" };
				sw.WriteLine("SndID__First = MusID__End");
				string last = "_First";
				for (int i = 0; i < musids.Count; i++)
				{
					if (i % 7 == 0)
						sw.Write("\tenum SndID_{0}=SndID_{1}", musids[i], last);
					else
						sw.Write(",SndID_{0}", musids[i]);
					if (i % 7 == 6)
					{
						sw.WriteLine();
						last = musids[i] + "+1";
					}
				}
				sw.WriteLine();
				musids = new List<string>(dac.Keys) { "_End" };
				sw.WriteLine("DACSFXID__First = SndID__End");
				last = "_First";
				for (int i = 0; i < musids.Count; i++)
				{
					if (i % 7 == 0)
						sw.Write("\tenum DACSFXID_{0}=DACSFXID_{1}", musids[i], last);
					else
						sw.Write(",DACSFXID_{0}", musids[i]);
					if (i % 7 == 6)
					{
						sw.WriteLine();
						last = musids[i] + "+1";
					}
				}
			}
			using (StreamWriter sw = new StreamWriter("sfxnames.gen.asm", false, Encoding.ASCII))
			{
				sw.WriteLine("SndNames:\toffsetTable");
				foreach (var item in sfx)
					sw.WriteLine("\toffsetTableEntry.w\tSndNam_{0}", item.Key);
				foreach (var item in dac)
					sw.WriteLine("\toffsetTableEntry.w\tDACSFXNam_{0}", item.Key);
				sw.WriteLine();
				foreach (var item in sfx)
					sw.WriteLine("SndNam_{0}:\tsongtext\t\"{1}\"", item.Key, item.Value.Title.ToUpperInvariant());
				foreach (var item in dac)
					sw.WriteLine("DACSFXNam_{0}:\tsongtext\t\"{1}\"", item.Key, item.Value.Title.ToUpperInvariant());
				sw.WriteLine("\teven");
			}
		}
	}

	class SFXInfo
	{
		public string Title { get; set; }
		public string File { get; set; }
		[IniIgnore]
		public byte Priority { get; set; }
		[IniName("Priority")]
		public string PriorityString
		{
			get { return Priority.ToString("X2"); }
			set { Priority = byte.Parse(value, System.Globalization.NumberStyles.HexNumber); }
		}
	}

	class DACInfo
	{
		public string Title { get; set; }
		public string Sample { get; set; }
	}
}
