using IniFile;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;

namespace KEHmusic
{
	static class Program
	{
		static byte[] GetTextFileBytes(string path)
		{
			// reads a text file and outputs a string that line endings normalized to \n
			string[] lines = File.ReadAllLines(path, Encoding.Default);
			using(MemoryStream ms = new MemoryStream())
			{
				for (int i = 0; i < lines.Length; i ++)
				{
					byte[] line = Encoding.Default.GetBytes(lines[i] + '\n');
					ms.Write(line, 0, line.Length);
				}
				return ms.ToArray();
			}
		}

		static string GetFileHash(System.Security.Cryptography.HashAlgorithm hashAlgo, string path, bool isText)
		{
			byte[] fileData = isText ? GetTextFileBytes(path) : File.ReadAllBytes(path);
			byte[] hashbytes = hashAlgo.ComputeHash(fileData);
			string hashstr = string.Empty;
			foreach (byte b in hashbytes)
				hashstr += b.ToString("x2");
			return hashstr;
		}

		static void Main(string[] args)
		{
			bool clean = args.Length > 0 && args[0].Equals("/clean", StringComparison.OrdinalIgnoreCase);
			if (clean)
				Console.WriteLine("Performing clean build of music data.");
			var dacs = IniSerializer.Deserialize<Dictionary<string, DACInfo>>("sound/DAC/DAC.ini");
			var samples = new List<KeyValuePair<string, int>>();
			foreach (var item in dacs.Select(a => a.Value.File).Distinct())
				samples.Add(new KeyValuePair<string, int>(item, (int)new FileInfo(Path.Combine("sound/DAC", item)).Length));
			List<int> dacbanksizes = new List<int>() { 0 };
			List<List<string>> dacbanks = new List<List<string>> { new List<string>() };
			foreach (var item in samples.OrderByDescending(a => a.Value))
			{
				bool found = false;
				for (int bank = 0; bank < dacbanksizes.Count; bank++)
					if (dacbanksizes[bank] + item.Value <= 0x8000)
					{
						dacbanks[bank].Add(item.Key);
						dacbanksizes[bank] += item.Value;
						found = true;
						break;
					}
				if (!found)
				{
					dacbanks.Add(new List<string>() { item.Key });
					dacbanksizes.Add(item.Value);
				}
			}
			var samplenums = new Dictionary<string, string>();
			using (StreamWriter sw = new StreamWriter("dacbanks.gen.asm", false, Encoding.ASCII))
			{
				for (int b = 0; b < dacbanks.Count; b++)
				{
					sw.WriteLine("SndDAC{0}_Start:\tstartBank", b + 1);
					sw.WriteLine();
					foreach (string item in dacbanks[b])
					{
						string label = Path.GetFileNameWithoutExtension(item).Replace(' ', '_').Replace('-', '_');
						samplenums.Add(item, label);
						sw.WriteLine("SndDAC_{0}:\tBINCLUDE \"sound/DAC/{1}\"", label, item);
						sw.WriteLine("SndDAC_{0}_End:", label);
						sw.WriteLine();
					}
					sw.WriteLine("\tfinishBank");
					sw.WriteLine();
				}
			}
			List<string> dacids = new List<string>(dacs.Count);
			using (StreamWriter sw = new StreamWriter("dacinfo.gen.asm", false, Encoding.ASCII))
			{
				sw.WriteLine("zDACMasterPlaylist:");
				sw.WriteLine();
				foreach (var item in dacs)
				{
					byte flags = 0;
					if (item.Value.Format == DACFormat.PCM)
						flags |= 1;
					if (item.Value.Priority)
						flags |= 2;

					sw.WriteLine("\tDACSample\tSndDAC_{0},{1},{2} ; {3}", samplenums[item.Value.File], item.Value.Rate, flags, item.Key);
					dacids.Add(item.Key);
				}
			}
			using (StreamWriter sw = new StreamWriter("dacids.gen.asm", false, Encoding.ASCII))
			{
				string last = "$81";
				for (int i = 0; i < dacids.Count; i++)
				{
					if (i % 7 == 0)
						sw.Write("\tenum {0}={1}", dacids[i], last);
					else
						sw.Write(",{0}", dacids[i]);
					if (i % 7 == 6)
					{
						sw.WriteLine();
						last = dacids[i] + "+1";
					}
				}
			}
			var songs = IniSerializer.Deserialize<Dictionary<string, MusicInfo>>("sound/music/music.ini");
			bool writeini = false;
			System.Security.Cryptography.MD5 md5hasher = System.Security.Cryptography.MD5.Create();
			foreach (var item in songs)
			{
				switch (Path.GetExtension(item.Value.File).ToLowerInvariant())
				{
					case ".asm":
					case ".68k":
						string md5 = GetFileHash(md5hasher, Path.Combine("sound/music", item.Value.File), true);
						if (clean || item.Value.MD5 != md5 || item.Value.Size <= 0 || (item.Value.OutputFile != null && !File.Exists(Path.Combine("sound/music", item.Value.OutputFile))))
						{
							Console.WriteLine("Building song \"{0}\"...", item.Value.Title);
							using (StreamWriter sw = new StreamWriter("tmp.asm", false, Encoding.ASCII))
							{
								sw.WriteLine("\tCPU 68000");
								sw.WriteLine("\tpadding off");
								sw.WriteLine("kehmusic = 1");
								sw.WriteLine("allOptimizations = 1");
								sw.WriteLine("\tinclude \"s2.macros.asm\"");
								sw.WriteLine("\tinclude \"sound/_smps2asm_inc.asm\"");
								sw.WriteLine("\tinclude \"sound/music/{0}\"", item.Value.File);
							}
							ProcessStartInfo si = new ProcessStartInfo("win32/as/asw", "-E -xx -A -r 2 -q -U tmp.asm")
							{
								CreateNoWindow = true
							};
							si.EnvironmentVariables.Add("AS_MSGPATH", "win32/as");
							si.EnvironmentVariables.Add("USEANSI", "n");
							si.UseShellExecute = false;
							using (Process proc = Process.Start(si))
								proc.WaitForExit();
							File.Delete("tmp.asm");
							if (File.Exists("tmp.log"))
							{
								Console.Write(File.ReadAllText("tmp.log"));
								File.Delete("tmp.log");
							}
							if (!File.Exists("tmp.p")) continue;
							si = new ProcessStartInfo("win32/s2p2bin", "tmp.p tmp.bin")
							{
								CreateNoWindow = true,
								UseShellExecute = false
							};
							using (Process proc = Process.Start(si))
								proc.WaitForExit();
							File.Delete("tmp.p");
							if (!File.Exists("tmp.bin")) continue;
							item.Value.Size = (short)new FileInfo("tmp.bin").Length;
							item.Value.MD5 = md5;
							if (item.Value.Size <= 0xA40)
							{
								item.Value.OutputFile = Path.GetFileNameWithoutExtension(item.Value.File) + "_cmp.bin";
								byte[] compressed_buffer = SonicRetro.KensSharp.Saxman.Compress("tmp.bin", true);
								if (item.Value.Size <= compressed_buffer.Length)
									item.Value.OutputFile = null;
								else
								{
									File.WriteAllBytes(Path.Combine("sound/music", item.Value.OutputFile), compressed_buffer);
									item.Value.Size = (short)compressed_buffer.Length;
								}
							}
							else
								item.Value.OutputFile = null;
							File.Delete("tmp.bin");
							writeini = true;
						}
						break;
					case ".bin":
						short size = (short)new FileInfo(Path.Combine("sound/music", item.Value.File)).Length;
						//string md5 = GetFileHash(md5hasher, Path.Combine("sound/music", item.Value.File), false);
						if (item.Value.Size != size)
						{
							item.Value.Size = size;
							writeini = true;
						}
						break;
				}
			}
			if (writeini)
				IniSerializer.Serialize(songs, "sound/music/music.ini");
			List<int> banksizes = new List<int>() { 0 };
			List<List<KeyValuePair<string, MusicInfo>>> banks = new List<List<KeyValuePair<string, MusicInfo>>>() { new List<KeyValuePair<string, MusicInfo>>() };
			foreach (var item in songs.OrderByDescending(a => a.Value.Size))
			{
				bool found = false;
				for (int i = 0; i < banks.Count; i++)
					if (banksizes[i] + item.Value.Size <= 0x8000)
					{
						banks[i].Add(item);
						banksizes[i] += item.Value.Size;
						found = true;
						break;
					}
				if (!found)
				{
					banks.Add(new List<KeyValuePair<string, MusicInfo>>() { item });
					banksizes.Add(item.Value.Size);
				}
			}
			using (StreamWriter sw = new StreamWriter("musicbanks.gen.asm", false, Encoding.ASCII))
			{
				for (int i = 0; i < banks.Count; i++)
				{
					sw.WriteLine("; ------------------------------------------------------------------------------");
					sw.WriteLine("; Music bank {0}", i + 1);
					sw.WriteLine("; ------------------------------------------------------------------------------");
					sw.WriteLine("SndMus{0}_Start:	startBank", i + 1);
					sw.WriteLine();
					foreach (var item in banks[i])
						switch (Path.GetExtension(item.Value.OutputFile ?? item.Value.File).ToLowerInvariant())
						{
							case ".asm":
							case ".68k":
								sw.WriteLine("Mus_{0}:\tinclude \"sound/music/{1}\" ; ${2:X} bytes", item.Key, item.Value.File, item.Value.Size);
								break;
							case ".bin":
								sw.WriteLine("Mus_{0}:\tBINCLUDE \"sound/music/{1}\" ; ${2:X} bytes", item.Key, item.Value.OutputFile ?? item.Value.File, item.Value.Size);
								break;
						}
					sw.WriteLine();
					sw.WriteLine("\tfinishBank");
					sw.WriteLine();
				}
			}
			using (StreamWriter sw = new StreamWriter("musicinfo.gen.asm", false, Encoding.ASCII))
			{
				sw.WriteLine("zMasterPlaylist:");
				foreach (var item in songs)
				{
					sw.Write("\tzmakePlaylistEntry\tMus_{0},", item.Key);
					switch (Path.GetExtension(item.Value.OutputFile ?? item.Value.File).ToLowerInvariant())
					{
						case ".asm":
						case ".68k":
							sw.Write("musprop_uncompressed");
							break;
						case ".bin":
							sw.Write("0");
							break;
					}
					if (item.Value.PALMode)
						sw.Write("|musprop_palmode");
					if (item.Value.ExtraLifeJingle)
						sw.Write("|musprop_1up");
					if (item.Value.NoSpeedUp)
						sw.Write("|musprop_nospeedup");
					sw.WriteLine();
				}
			}
			using (StreamWriter sw = new StreamWriter("musicids.gen.asm", false, Encoding.ASCII))
			{
				List<string> musids = new List<string>(songs.Keys) { "_End" };
				sw.WriteLine("MusID__First = 1");
				string last = "_First";
				for (int i = 0; i < musids.Count; i++)
				{
					if (i % 7 == 0)
						sw.Write("\tenum MusID_{0}=MusID_{1}", musids[i], last);
					else
						sw.Write(",MusID_{0}", musids[i]);
					if (i % 7 == 6)
					{
						sw.WriteLine();
						last = musids[i] + "+1";
					}
				}
			}
			using (StreamWriter sw = new StreamWriter("musicnames.gen.asm", false, Encoding.ASCII))
			{
				sw.WriteLine("SongNames:\toffsetTable");
				sw.WriteLine("\toffsetTableEntry.w\tMusNam_Null");
				foreach (var item in songs)
					sw.WriteLine("\toffsetTableEntry.w\tMusNam_{0}", item.Key);
				sw.WriteLine();
				sw.WriteLine("MusNam_Null:\tdc.b 0,' '");
				foreach (var item in songs)
					sw.WriteLine("MusNam_{0}:\tsongtext\t\"{1}\"", item.Key, item.Value.Title.ToUpperInvariant());
				sw.WriteLine("\teven");
			}
		}
	}

	class MusicInfo
	{
		public string Title { get; set; }
		public string Author { get; set; }
		public string File { get; set; }
		public bool PALMode { get; set; }
		public bool ExtraLifeJingle { get; set; }
		public bool NoSpeedUp { get; set; }
		public short Size { get; set; }
		public string MD5 { get; set; }
		public string OutputFile { get; set; }
	}

	class DACInfo
	{
		public string File { get; set; }
		public int Rate { get; set; }
		public DACFormat Format { get; set; }
		public bool Priority { get; set; }
	}

	enum DACFormat { DPCM, PCM }
}
