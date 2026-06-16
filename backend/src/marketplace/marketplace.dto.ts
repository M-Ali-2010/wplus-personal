export class CreateJobDto {
  title: string;
  description: string;
  category: string;
  budget: number;
  currency?: string;
  tags?: string[];
}

export class ApplyJobDto {
  coverLetter?: string;
}
